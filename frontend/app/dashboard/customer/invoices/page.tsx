'use client'

import { apiClient } from '@/lib/api'
import { useEffect, useState } from 'react'
import { FileText, Download, IndianRupee } from 'lucide-react'

interface Invoice {
  id: string
  amount_total: number
  amount_paid: number
  status: string
  issued_at: string
  billing_period_start: string
  billing_period_end: string
  hosted_invoice_url?: string
  invoice_pdf?: string
  line_items?: {
    product_name: string
    quantity: number
    unit_price: number
    total: number
  }[]
}

interface SavingsData {
  total_saved: number
  current_month_savings: number
}

function InvoiceCard({ inv }: { inv: Invoice }) {
  const [expanded, setExpanded] = useState(false)

  return (
    <div className="bg-white rounded-2xl shadow-card overflow-hidden transition-all duration-300">
      <div 
        className="p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 cursor-pointer hover:bg-gray-50"
        onClick={() => setExpanded(!expanded)}
      >
        <div className="flex items-center gap-4">
          <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
            inv.status === 'paid' ? 'bg-green-50 text-green-600' :
            inv.status === 'draft' ? 'bg-gray-100 text-gray-400' :
            'bg-red-50 text-red-500'
          }`}>
            <FileText className="w-5 h-5" />
          </div>
          <div>
            <p className="text-sm font-semibold">
              LifeKart Monthly Invoice — {new Date(inv.billing_period_start).toLocaleDateString('en-IN', { month: 'long', year: 'numeric' })}
            </p>
            <p className="text-xs text-gray-400">
              Billing Period: {new Date(inv.billing_period_start).toLocaleDateString('en-IN')} to {new Date(inv.billing_period_end).toLocaleDateString('en-IN')}
            </p>
          </div>
        </div>
        
        <div className="flex items-center gap-6 justify-between md:justify-end">
          <div className="text-right">
            <div className="text-lg font-display font-extrabold">
              ₹{Number(inv.amount_total).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </div>
            {/* <span className={`text-xs font-bold uppercase ${
              inv.status === 'paid' ? 'text-green-600' : 'text-gray-400'
            }`}>
              {inv.status}
            </span> */}
          </div>
          
          {/* Download / View Bill Button */}
          {(inv.hosted_invoice_url || inv.invoice_pdf) ? (
            <a 
              href={inv.invoice_pdf || inv.hosted_invoice_url} 
              target="_blank" 
              rel="noopener noreferrer"
              onClick={(e) => e.stopPropagation()}
              className="flex items-center gap-2 px-4 py-2 bg-black text-white text-xs font-bold uppercase rounded-xl hover:bg-gray-800 transition-colors"
            >
              <Download className="w-4 h-4" /> Bill
            </a>
          ) : (
            <button 
              disabled
              onClick={(e) => e.stopPropagation()}
              className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-400 text-xs font-bold uppercase rounded-xl"
            >
              No PDF
            </button>
          )}
        </div>
      </div>
      
      {/* Accordion Content */}
      {expanded && inv.line_items && inv.line_items.length > 0 && (
        <div className="px-5 pb-5 pt-2 border-t border-gray-100 bg-gray-50/50">
          <h4 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3 mt-2">Delivery Breakdown</h4>
          <div className="space-y-2">
            {inv.line_items.map((item, idx) => (
              <div key={idx} className="flex justify-between items-center text-sm">
                <span className="font-medium text-gray-700">
                  {item.product_name} <span className="text-gray-400 text-xs mx-1">x</span> {item.quantity} units
                </span>
                <span className="font-bold text-gray-900">
                  ₹{Number(item.total).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default function InvoicesPage() {
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [savings, setSavings] = useState<SavingsData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function load() {
      try {
        const [data, savingsData] = await Promise.all([
          apiClient('/payments/invoices').catch(() => []),
          apiClient('/price-protection/savings/me').catch(() => null)
        ])
        setInvoices(Array.isArray(data) ? data : [])
        setSavings(savingsData)
      } catch { } finally { setLoading(false) }
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="space-y-4 animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-48" />
        {[1, 2, 3].map(i => <div key={i} className="h-20 bg-gray-100 rounded-2xl" />)}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl md:text-4xl font-display font-extrabold uppercase tracking-tighter">Invoices</h1>
      </div>

      {savings && (savings.current_month_savings > 0 || savings.total_saved > 0) && (
        <div className="bg-green-50 border border-green-200 rounded-2xl p-6">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center flex-shrink-0">
              <IndianRupee className="w-6 h-6 text-green-600" />
            </div>
            <div>
              <h2 className="text-2xl md:text-3xl font-display font-extrabold text-green-800 tracking-tight uppercase">
                You are saving ₹{Number(savings.current_month_savings).toLocaleString('en-IN', { maximumFractionDigits: 0 })} this month!
              </h2>
              <p className="text-sm text-green-600/80 mt-2">
                Your LifeKart Price Ceiling automatically locked in lower prices against inflation.
              </p>
            </div>
          </div>
        </div>
      )}

      {invoices.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-2xl shadow-card">
          <FileText className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 font-bold uppercase tracking-wider">No invoices yet</p>
          <p className="text-sm text-gray-400 mt-1">Invoices are generated monthly</p>
        </div>
      ) : (
        <div className="space-y-3">
          {invoices.map((inv) => (
            <InvoiceCard key={inv.id} inv={inv} />
          ))}
        </div>
      )}
    </div>
  )
}