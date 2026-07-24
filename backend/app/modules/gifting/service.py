import uuid
from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.settings_loader import load_setting
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.modules.gifting.models import GiftOrder, GiftOrderItem
from app.modules.gifting.schemas import GiftOrderCreate, GiftOrderItemCreate, GiftClaimCreate
from app.modules.catalog.models import Product
from app.modules.calculator.models import LifetimeSubscription
from app.modules.profiling.models import Household


class GiftingService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_gift_order(self, user_id: uuid.UUID, data: GiftOrderCreate) -> GiftOrder:
        result = await self.db.execute(
            select(Household).where(Household.user_id == user_id)
        )
        household = result.scalar_one_or_none()
        if not household:
            raise ValueError("Create your household profile first")

        total_value = Decimal("0")
        items_data: list[tuple[GiftOrderItemCreate, Decimal]] = []

        for item_data in data.items:
            result = await self.db.execute(
                select(Product).where(
                    Product.id == item_data.product_id,
                    Product.is_active == True,
                )
            )
            product = result.scalar_one_or_none()
            if not product:
                raise ValueError(f"Product {item_data.product_id} not found or inactive")

            locked_price = product.unit_price_wholesale
            duration_years = data.end_age - item_data.age_trigger
            deliveries_per_year = 365 / item_data.frequency_days
            item_total = locked_price * Decimal(str(item_data.quantity_per_delivery)) * Decimal(str(deliveries_per_year)) * Decimal(str(duration_years))
            total_value += item_total
            items_data.append((item_data, locked_price))

        gift = GiftOrder(
            benefactor_household_id=household.id,
            beneficiary_name=data.beneficiary_name,
            beneficiary_dob=data.beneficiary_dob,
            beneficiary_relationship=data.beneficiary_relationship,
            start_age=min(item.age_trigger for item in data.items),
            end_age=data.end_age,
            status="active",
            total_value_locked=total_value,
            payment_status="pending",
        )
        self.db.add(gift)
        await self.db.commit()

        for item_data, locked_price in items_data:
            item = GiftOrderItem(
                gift_order_id=gift.id,
                product_id=item_data.product_id,
                age_trigger=item_data.age_trigger,
                size_progression=item_data.size_progression,
                locked_price=locked_price,
                frequency_days=item_data.frequency_days,
                quantity_per_delivery=item_data.quantity_per_delivery,
            )
            self.db.add(item)

        await self.db.commit()
        return await self._get_with_items(gift.id)

    async def get_my_gift_orders(self, user_id: uuid.UUID) -> list[GiftOrder]:
        result = await self.db.execute(
            select(Household).where(Household.user_id == user_id)
        )
        household = result.scalar_one_or_none()
        if not household:
            return []

        result = await self.db.execute(
            select(GiftOrder)
            .where(GiftOrder.benefactor_household_id == household.id)
            .options(selectinload(GiftOrder.items))
            .order_by(GiftOrder.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_received_gifts(self, user_id: uuid.UUID) -> list[GiftOrder]:
        household = await self.db.scalar(select(Household).where(Household.user_id == user_id))
        if not household:
            return []
            
        result = await self.db.execute(
            select(GiftOrder)
            .where(GiftOrder.recipient_household_id == household.id)
            .options(selectinload(GiftOrder.items).joinedload(GiftOrderItem.product))
            .order_by(GiftOrder.created_at.desc())
        )
        return result.scalars().all()

    async def get_received_subscriptions(self, user_id: uuid.UUID) -> list:
        household = await self.db.scalar(select(Household).where(Household.user_id == user_id))
        if not household:
            return []
            
        gifts = await self.db.execute(
            select(GiftOrder).where(GiftOrder.recipient_household_id == household.id)
        )
        
        gift_ids = [g.id for g in gifts.scalars()]
        if not gift_ids:
            return []
            
        subs = await self.db.execute(
            select(LifetimeSubscription)
            .options(selectinload(LifetimeSubscription.product))
            .where(
                LifetimeSubscription.source == "gift",
                LifetimeSubscription.source_id.in_(gift_ids)
            )
        )
        return list(subs.scalars().all())

    async def get_received_deliveries(self, user_id: uuid.UUID) -> list:
        household = await self.db.scalar(select(Household).where(Household.user_id == user_id))
        if not household:
            return []
            
        gifts = await self.db.execute(
            select(GiftOrder).where(GiftOrder.recipient_household_id == household.id)
        )
        
        gift_ids = [g.id for g in gifts.scalars()]
        if not gift_ids:
            return []
            
        subs = await self.db.execute(
            select(LifetimeSubscription.id)
            .where(
                LifetimeSubscription.source == "gift",
                LifetimeSubscription.source_id.in_(gift_ids)
            )
        )
        sub_ids = [s_id for s_id in subs.scalars()]
        if not sub_ids:
            return []
            
        from app.modules.scheduling.models import DeliveryEvent
        deliveries = await self.db.execute(
            select(DeliveryEvent)
            .options(selectinload(DeliveryEvent.product))
            .where(DeliveryEvent.subscription_id.in_(sub_ids))
            .order_by(DeliveryEvent.scheduled_date.desc())
        )
        return list(deliveries.scalars().all())

    async def get_gift_order(self, gift_order_id: uuid.UUID) -> GiftOrder:
        result = await self.db.execute(
            select(GiftOrder)
            .where(GiftOrder.id == gift_order_id)
            .options(selectinload(GiftOrder.items))
        )
        gift = result.scalar_one_or_none()
        if not gift:
            raise ValueError("Gift order not found")
        return gift

    async def get_public_gift_info(self, gift_order_id: uuid.UUID) -> dict:
        result = await self.db.execute(
            select(GiftOrder)
            .where(GiftOrder.id == gift_order_id)
            .options(selectinload(GiftOrder.items).joinedload(GiftOrderItem.product))
        )
        gift = result.scalar_one_or_none()
        if not gift:
            raise ValueError("Gift order not found")
        
        items = []
        for item in gift.items:
            items.append({
                "product_name": item.product.name,
                "frequency_days": item.frequency_days,
                "quantity_per_delivery": item.quantity_per_delivery
            })
            
        return {
            "id": gift.id,
            "beneficiary_name": gift.beneficiary_name,
            "start_age": gift.start_age,
            "end_age": gift.end_age,
            "items": items,
            "claimed": gift.claimed_at is not None,
            "status": gift.status
        }

    async def claim_gift(self, gift_order_id: uuid.UUID, data: GiftClaimCreate, user_id: uuid.UUID) -> dict:
        from datetime import datetime
        gift = await self.get_gift_order(gift_order_id)
        if gift.payment_status != "paid":
            raise ValueError("Gift has not been activated by the sender yet.")
        if gift.claimed_at:
            raise ValueError("Gift has already been claimed.")
            
        household = await self.db.scalar(select(Household).where(Household.user_id == user_id))
        
        from app.modules.users.models import User
        from app.modules.profiling.models import Member
        from app.modules.health.models import HealthProfile

        user = await self.db.scalar(select(User).where(User.id == user_id))
        
        if not household:
            household = Household(
                user_id=user_id,
                address_line1=data.address.line1,
                address_line2=data.address.line2,
                city=data.address.city,
                state=data.address.state,
                pincode=data.address.pincode,
                prefer_organic=False
            )
            self.db.add(household)
            await self.db.flush()
            
        # Ensure self member exists
        self_member = await self.db.scalar(select(Member).where(Member.household_id == household.id, Member.family_relation == "self"))
        if not self_member:
            self_name = user.full_name if user else "Parent/Guardian"
            if user and user.full_name.lower().strip() == gift.beneficiary_name.lower().strip():
                self_name = gift.beneficiary_name
            
            self_member = Member(
                household_id=household.id,
                full_name=self_name,
                family_relation="self",
                date_of_birth=gift.beneficiary_dob if self_name == gift.beneficiary_name else date(1990, 1, 1)
            )
            self.db.add(self_member)
            await self.db.flush()
            self.db.add(HealthProfile(member_id=self_member.id, existing_conditions=[], allergies=[]))
            
        # Ensure beneficiary member exists (if it's not the user themselves)
        if not (user and user.full_name.lower().strip() == gift.beneficiary_name.lower().strip()):
            beneficiary_member = await self.db.scalar(select(Member).where(Member.household_id == household.id, Member.full_name.ilike(gift.beneficiary_name)))
            if not beneficiary_member:
                beneficiary_member = Member(
                    household_id=household.id,
                    full_name=gift.beneficiary_name,
                    family_relation="child",
                    date_of_birth=gift.beneficiary_dob
                )
                self.db.add(beneficiary_member)
                await self.db.flush()
                self.db.add(HealthProfile(member_id=beneficiary_member.id, existing_conditions=[], allergies=[]))
            
            
        gift.recipient_household_id = household.id
        gift.recipient_address = data.address.model_dump()
        gift.claimed_at = datetime.utcnow()
        
        result = await self.db.execute(
            select(LifetimeSubscription).where(
                LifetimeSubscription.source == "gift",
                LifetimeSubscription.source_id == gift.id,
            )
        )
        for sub in result.scalars().all():
            sub.delivery_address_override = gift.recipient_address
            
        await self.db.commit()
        return {"status": "success", "claimed_at": str(gift.claimed_at)}

    async def _verify_ownership(self, user_id: uuid.UUID, gift: GiftOrder) -> None:
        result = await self.db.execute(
            select(Household).where(
                Household.id == gift.benefactor_household_id,
                Household.user_id == user_id,
            )
        )
        if not result.scalar_one_or_none():
            raise ValueError("Gift order does not belong to you")

    async def activate_gift_order(self, user_id: uuid.UUID, gift_order_id: uuid.UUID) -> dict:
        gift = await self.get_gift_order(gift_order_id)
        await self._verify_ownership(user_id, gift)

        if gift.status != "active":
            raise ValueError(f"Cannot activate gift with status '{gift.status}'")

        triggered_items = []
        any_existing = False
        today = date.today()

        ceiling_config = await load_setting(self.db, "default_price_ceiling_pct")
        ceiling_pct = Decimal(str(ceiling_config["pct"]))

        for item in gift.items:
            trigger_date = gift.beneficiary_dob + timedelta(days=int(item.age_trigger * 365.25))
            if today < trigger_date:
                continue

            end_date = gift.beneficiary_dob + timedelta(days=int(gift.end_age * 365.25))

            existing = await self.db.execute(
                select(LifetimeSubscription).where(
                    LifetimeSubscription.household_id == gift.benefactor_household_id,
                    LifetimeSubscription.product_id == item.product_id,
                    LifetimeSubscription.source == "gift",
                    LifetimeSubscription.source_id == gift.id,
                )
            )
            if existing.scalar_one_or_none():
                # Already activated
                any_existing = True
                continue

            sub = LifetimeSubscription(
                household_id=gift.benefactor_household_id,
                member_id=None,
                product_id=item.product_id,
                quantity_per_delivery=item.quantity_per_delivery,
                frequency_days=item.frequency_days,
                start_date=trigger_date,
                end_date=end_date,
                next_delivery_date=trigger_date,
                status="active",
                source="gift",
                source_id=gift.id,
                locked_unit_price=item.locked_price,
                price_ceiling_pct=ceiling_pct,
            )
            self.db.add(sub)
            triggered_items.append({
                "product_id": str(item.product_id),
                "start_date": str(trigger_date),
                "end_date": str(end_date),
            })

        if not triggered_items and not any_existing and gift.payment_status == "pending":
            raise ValueError("No items are ready for activation yet (age trigger not reached)")

        gift.payment_status = "paid"
        await self.db.commit()
        
        return {
            "gift_order_id": str(gift.id),
            "subscriptions_created": len(triggered_items),
            "items": triggered_items,
        }

    async def cancel_gift_order(self, user_id: uuid.UUID, gift_order_id: uuid.UUID) -> GiftOrder:
        gift = await self.get_gift_order(gift_order_id)
        await self._verify_ownership(user_id, gift)

        if gift.status not in ("active", "paused"):
            raise ValueError(f"Cannot cancel gift with status '{gift.status}'")

        gift.status = "completed"

        result = await self.db.execute(
            select(LifetimeSubscription).where(
                LifetimeSubscription.source == "gift",
                LifetimeSubscription.source_id == gift.id,
            )
        )
        for sub in result.scalars().all():
            sub.status = "cancelled"

        await self.db.flush()
        return await self._get_with_items(gift.id)

    async def _get_with_items(self, gift_order_id: uuid.UUID) -> GiftOrder:
        result = await self.db.execute(
            select(GiftOrder)
            .where(GiftOrder.id == gift_order_id)
            .options(selectinload(GiftOrder.items))
        )
        return result.scalar_one()