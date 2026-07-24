import uuid
from datetime import date, datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.orm import joinedload
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.legacy.models import LegacyNominee, LegacyActivation
from app.modules.legacy.schemas import (
    LegacyNomineeCreate,
    LegacyNomineeUpdate,
    DeathVerificationRequest,
    PublicClaimRequest,
)
from app.core.security import encrypt_data, decrypt_data, hash_password
from app.modules.calculator.models import LifetimeSubscription
from app.modules.profiling.models import Household
from app.modules.users.models import User


class LegacyService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def _get_household(self, user_id: uuid.UUID) -> Household:
        result = await self.db.execute(select(Household).where(Household.user_id == user_id))
        household = result.scalar_one_or_none()
        if not household:
            raise ValueError("Household not found for this user")
        return household

    async def add_nominee(self, user_id: uuid.UUID, data: LegacyNomineeCreate) -> LegacyNominee:
        household = await self._get_household(user_id)

        # Validation: Check for duplicates globally across the entire platform
        result = await self.db.execute(select(LegacyNominee))
        existing_nominees = result.scalars().all()
        for en in existing_nominees:
            if en.nominee_phone == data.nominee_phone:
                raise ValueError("A nominee with this mobile number already exists.")
            if data.nominee_email and en.nominee_email == data.nominee_email:
                raise ValueError("A nominee with this email already exists.")
            if data.nominee_aadhaar and en.nominee_aadhaar:
                decrypted = decrypt_data(en.nominee_aadhaar)
                if decrypted == data.nominee_aadhaar:
                    raise ValueError("A nominee with this Aadhaar number already exists.")

        if data.is_primary:
            await self._unset_primary(household.id)

        nominee = LegacyNominee(
            household_id=household.id,
            nominee_name=data.nominee_name,
            nominee_relationship=data.nominee_relationship,
            nominee_phone=data.nominee_phone,
            nominee_email=data.nominee_email,
            nominee_aadhaar=encrypt_data(data.nominee_aadhaar) if data.nominee_aadhaar else None,
            is_primary=data.is_primary,
        )
        self.db.add(nominee)
        await self.db.commit()
        await self.db.refresh(nominee)
        return nominee

    async def get_nominees(self, user_id: uuid.UUID) -> list[LegacyNominee]:
        household = await self._get_household(user_id)
        result = await self.db.execute(
            select(LegacyNominee)
            .where(LegacyNominee.household_id == household.id)
            .order_by(LegacyNominee.is_primary.desc(), LegacyNominee.created_at.desc())
        )
        return list(result.scalars().all())

    async def update_nominee(self, user_id: uuid.UUID, nominee_id: uuid.UUID, data: LegacyNomineeUpdate) -> LegacyNominee:
        household = await self._get_household(user_id)

        result = await self.db.execute(
            select(LegacyNominee).where(
                LegacyNominee.id == nominee_id,
                LegacyNominee.household_id == household.id,
            )
        )
        nominee = result.scalar_one_or_none()
        if not nominee:
            raise ValueError("Nominee not found")

        # Validation: Check for duplicates globally across the entire platform
        result_all = await self.db.execute(select(LegacyNominee))
        existing_nominees = result_all.scalars().all()
        for en in existing_nominees:
            if en.id == nominee_id:
                continue
            if data.nominee_phone and en.nominee_phone == data.nominee_phone:
                raise ValueError("A nominee with this mobile number already exists.")
            if data.nominee_email and en.nominee_email == data.nominee_email:
                raise ValueError("A nominee with this email already exists.")
            if data.nominee_aadhaar and en.nominee_aadhaar:
                decrypted = decrypt_data(en.nominee_aadhaar)
                if decrypted == data.nominee_aadhaar:
                    raise ValueError("A nominee with this Aadhaar number already exists.")

        if data.is_primary and not nominee.is_primary:
            await self._unset_primary(household.id)

        for field, value in data.model_dump(exclude_unset=True).items():
            if field == "nominee_aadhaar" and value is not None:
                value = encrypt_data(value)
            setattr(nominee, field, value)

        await self.db.commit()
        await self.db.refresh(nominee)
        return nominee

    async def delete_nominee(self, user_id: uuid.UUID, nominee_id: uuid.UUID) -> None:
        household = await self._get_household(user_id)

        result = await self.db.execute(
            select(LegacyNominee).where(
                LegacyNominee.id == nominee_id,
                LegacyNominee.household_id == household.id,
            )
        )
        nominee = result.scalar_one_or_none()
        if not nominee:
            raise ValueError("Nominee not found")

        activation_check = await self.db.execute(
            select(LegacyActivation).where(
                LegacyActivation.successor_nominee_id == nominee_id,
                LegacyActivation.status.in_(["pending_verification", "verified", "in_progress"]),
            )
        )
        if activation_check.scalar_one_or_none():
            raise ValueError("Cannot delete nominee with active legacy activation")

        await self.db.delete(nominee)
        await self.db.commit()

    async def verify_death_and_activate(
        self, user_id: uuid.UUID, data: DeathVerificationRequest
    ) -> LegacyActivation:
        household = await self._get_household(user_id)

        result = await self.db.execute(
            select(LegacyNominee).where(
                LegacyNominee.id == data.nominee_id,
                LegacyNominee.household_id == household.id,
            )
        )
        nominee = result.scalar_one_or_none()
        if not nominee:
            raise ValueError("Nominee not found")

        existing = await self.db.execute(
            select(LegacyActivation).where(
                LegacyActivation.household_id == household.id,
                LegacyActivation.status.in_(["pending_verification", "verified", "in_progress"]),
            )
        )
        if existing.scalar_one_or_none():
            raise ValueError("An active legacy activation already exists for this household")

        active_subs_result = await self.db.execute(
            select(func.count(LifetimeSubscription.id)).where(
                LifetimeSubscription.household_id == household.id,
                LifetimeSubscription.status == "active",
            )
        )
        sub_count = active_subs_result.scalar_one()

        activation = LegacyActivation(
            household_id=household.id,
            original_user_id=user_id,
            successor_nominee_id=nominee.id,
            active_subscriptions_count=sub_count,
            status="pending_verification",
            death_certificate_url=data.proof_document_url,
            activation_notes=data.notes,
        )
        self.db.add(activation)

        await self.db.commit()
        result = await self.db.execute(
            select(LegacyActivation)
            .options(
                joinedload(LegacyActivation.successor_nominee),
                joinedload(LegacyActivation.original_user)
            )
            .where(LegacyActivation.id == activation.id)
        )
        return result.scalar_one()

    async def verify_public_claim(self, data: PublicClaimRequest) -> LegacyActivation:
        result = await self.db.execute(select(User).where(User.email == data.deceased_email))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("No account found with this email.")
        
        household = await self._get_household(user.id)
        
        result = await self.db.execute(
            select(LegacyNominee).where(
                LegacyNominee.household_id == household.id,
                LegacyNominee.nominee_email == data.nominee_email
            )
        )
        nominee = result.scalar_one_or_none()
        if not nominee:
            raise ValueError("No matching nominee record found for this email.")
            
        existing = await self.db.execute(
            select(LegacyActivation).where(
                LegacyActivation.household_id == household.id,
                LegacyActivation.status.in_(["pending_verification", "verified", "in_progress"]),
            )
        )
        if existing.scalar_one_or_none():
            raise ValueError("An active legacy activation already exists for this household")

        active_subs_result = await self.db.execute(
            select(func.count(LifetimeSubscription.id)).where(
                LifetimeSubscription.household_id == household.id,
                LifetimeSubscription.status == "active",
            )
        )
        sub_count = active_subs_result.scalar_one()

        activation = LegacyActivation(
            household_id=household.id,
            original_user_id=user.id,
            successor_nominee_id=nominee.id,
            active_subscriptions_count=sub_count,
            status="pending_verification",
            death_certificate_url=data.proof_document_url,
            activation_notes=data.notes,
        )
        self.db.add(activation)

        await self.db.commit()
        result = await self.db.execute(
            select(LegacyActivation)
            .options(
                joinedload(LegacyActivation.successor_nominee),
                joinedload(LegacyActivation.original_user)
            )
            .where(LegacyActivation.id == activation.id)
        )
        return result.scalar_one()

    async def get_pending_activations(self, status_filter: str = "pending_verification") -> list[LegacyActivation]:
        query = select(LegacyActivation).options(
            joinedload(LegacyActivation.successor_nominee),
            joinedload(LegacyActivation.original_user)
        )
        if status_filter != "all":
            query = query.where(LegacyActivation.status == status_filter)
        
        result = await self.db.execute(query.order_by(LegacyActivation.created_at.desc()))
        return list(result.scalars().all())

    async def approve_activation(self, activation_id: uuid.UUID) -> LegacyActivation:
        result = await self.db.execute(
            select(LegacyActivation)
            .options(
                joinedload(LegacyActivation.successor_nominee),
                joinedload(LegacyActivation.original_user)
            )
            .where(LegacyActivation.id == activation_id)
        )
        activation = result.scalar_one_or_none()
        if not activation:
            raise ValueError("Activation not found")

        if activation.status != "pending_verification":
            raise ValueError(f"Activation is in status '{activation.status}', expected 'pending_verification'")

        now = datetime.utcnow()
        activation.status = "verified"
        activation.deceased_verified_at = now

        result = await self.db.execute(
            select(LegacyNominee).where(LegacyNominee.id == activation.successor_nominee_id)
        )
        nominee = result.scalar_one()
        nominee.is_verified = True
        nominee.verification_status = "verified"

        result = await self.db.execute(
            select(Household).where(Household.id == nominee.household_id)
        )
        original_household = result.scalar_one()

        result = await self.db.execute(
            select(User).where(User.id == original_household.user_id)
        )
        user = result.scalar_one()
        user.is_active = False

        # --- AUTO-PROVISION NOMINEE ACCOUNT ---
        # Check if the nominee already has an account by email
        result = await self.db.execute(
            select(User).where(User.email == nominee.nominee_email)
        )
        nominee_user = result.scalar_one_or_none()

        if not nominee_user:
            # Check if phone number is already taken by a different user
            if nominee.nominee_phone:
                result_phone = await self.db.execute(
                    select(User).where(User.phone == nominee.nominee_phone)
                )
                if result_phone.scalar_one_or_none():
                    raise ValueError(f"Cannot auto-provision Nominee: The phone number {nominee.nominee_phone} is already linked to another account.")
            
            # Create a brand new user account for the nominee
            nominee_user = User(
                email=nominee.nominee_email,
                phone=nominee.nominee_phone,
                full_name=nominee.nominee_name,
                role="customer",
                hashed_password=hash_password("welcome@123"),
                is_active=True,
            )
            self.db.add(nominee_user)
            await self.db.flush()
        # --------------------------------------

        new_household = Household(
            user_id=nominee_user.id,
            address_line1=original_household.address_line1,
            address_line2=original_household.address_line2,
            city=original_household.city,
            state=original_household.state,
            pincode=original_household.pincode,
            monthly_grocery_budget=original_household.monthly_grocery_budget,
            prefer_organic=original_household.prefer_organic,
        )
        self.db.add(new_household)
        await self.db.flush()

        activation.transfer_household_id = new_household.id
        activation.activated_at = now
        activation.status = "in_progress"

        result = await self.db.execute(
            select(LifetimeSubscription).where(
                LifetimeSubscription.household_id == nominee.household_id,
                LifetimeSubscription.status == "active",
            )
        )
        old_subs = list(result.scalars().all())

        today = date.today()
        inherited_end_date = date(today.year + 50, today.month, today.day)

        transferred = 0
        for old_sub in old_subs:
            old_end_date = old_sub.end_date
            old_sub.end_date = today
            old_sub.status = "legacy_transferred"

            new_sub = LifetimeSubscription(
                household_id=new_household.id,
                member_id=old_sub.member_id,
                product_id=old_sub.product_id,
                quantity_per_delivery=old_sub.quantity_per_delivery,
                frequency_days=old_sub.frequency_days,
                start_date=today + timedelta(days=1),
                end_date=inherited_end_date,
                next_delivery_date=old_sub.next_delivery_date,
                status="active",
                source="legacy",
                source_id=activation.id,
                locked_unit_price=old_sub.locked_unit_price,
                price_ceiling_pct=old_sub.price_ceiling_pct,
            )
            self.db.add(new_sub)
            transferred += 1

        activation.transferred_count = transferred
        activation.status = "completed"
        activation.activation_notes = (
            f"{(activation.activation_notes or '').rstrip('.')}. "
            f"{transferred} subscriptions transferred to new household."
        ).strip()

        await self.db.commit()
        await self.db.refresh(activation)
        return activation

    async def reject_activation(self, activation_id: uuid.UUID, reason: str) -> LegacyActivation:
        result = await self.db.execute(
            select(LegacyActivation)
            .options(
                joinedload(LegacyActivation.successor_nominee),
                joinedload(LegacyActivation.original_user)
            )
            .where(LegacyActivation.id == activation_id)
        )
        activation = result.scalar_one_or_none()
        if not activation:
            raise ValueError("Activation not found")

        if activation.status != "pending_verification":
            raise ValueError(f"Activation is in status '{activation.status}', expected 'pending_verification'")

        activation.status = "rejected"
        activation.rejection_reason = reason
        
        await self.db.commit()
        await self.db.refresh(activation)
        return activation

    async def get_pending_nominees(self) -> list[LegacyNominee]:
        result = await self.db.execute(
            select(LegacyNominee)
            .where(LegacyNominee.is_verified == False)
            .order_by(LegacyNominee.created_at.desc())
        )
        return list(result.scalars().all())

    async def verify_nominee(self, nominee_id: uuid.UUID) -> LegacyNominee:
        result = await self.db.execute(
            select(LegacyNominee).where(LegacyNominee.id == nominee_id)
        )
        nominee = result.scalar_one_or_none()
        if not nominee:
            raise ValueError("Nominee not found")
            
        # Validation: Check for duplicates globally across the entire platform before verifying
        result_all = await self.db.execute(select(LegacyNominee).where(LegacyNominee.id != nominee_id))
        existing_nominees = result_all.scalars().all()
        for en in existing_nominees:
            if nominee.nominee_phone and en.nominee_phone == nominee.nominee_phone:
                raise ValueError("Another nominee with this mobile number already exists.")
            if nominee.nominee_email and en.nominee_email == nominee.nominee_email:
                raise ValueError("Another nominee with this email already exists.")
            if nominee.nominee_aadhaar and en.nominee_aadhaar:
                if decrypt_data(en.nominee_aadhaar) == decrypt_data(nominee.nominee_aadhaar):
                    raise ValueError("Another nominee with this Aadhaar number already exists.")
        
        nominee.is_verified = True
        nominee.verification_status = "verified"
        await self.db.commit()
        await self.db.refresh(nominee)
        return nominee

    async def _unset_primary(self, household_id: uuid.UUID) -> None:
        result = await self.db.execute(
            select(LegacyNominee).where(
                LegacyNominee.household_id == household_id,
                LegacyNominee.is_primary == True,
            )
        )
        for nominee in result.scalars().all():
            nominee.is_primary = False