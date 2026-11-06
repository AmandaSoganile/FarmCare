from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator, model_validator


class Input(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=False)


class EmailInput(Input):
    email: EmailStr

    @field_validator("email", mode="before")
    @classmethod
    def normalize_email(cls, value):
        return value.strip().lower() if isinstance(value, str) else value


class Login(EmailInput):
    password: str = Field(min_length=1, max_length=128)


class Register(EmailInput):
    name: str = Field(min_length=1, max_length=120)
    password: str = Field(min_length=8, max_length=128)

    @field_validator("name")
    @classmethod
    def clean_name(cls, value):
        if not value.strip():
            raise ValueError("Enter your name")
        return value.strip()


class TokenInput(Input):
    token: str = Field(min_length=20, max_length=256)


class Reset(TokenInput):
    password: str = Field(min_length=8, max_length=128)


class Refresh(Input):
    refresh_token: str = Field(min_length=20, max_length=256)


class ProfileUpdate(Input):
    name: str = Field(min_length=1, max_length=120)

    @field_validator("name")
    @classmethod
    def clean_name(cls, value):
        if not value.strip():
            raise ValueError("Enter your name")
        return value.strip()


class AnimalData(Input):
    name: str = Field(min_length=1, max_length=120)
    species: Literal["Cow", "Chicken", "Pig"]
    breed: str = Field(max_length=120)
    weight: int = Field(ge=0, le=100000, strict=True)
    feed_type: str = Field(max_length=200)
    feed_schedule: int = Field(ge=0, le=100, strict=True)
    vaccination_type: str = Field(max_length=200)
    vaccination_frequency: Literal[1, 2, 3, 4, 6, 8, 12, 24]
    last_vaccination_date: datetime
    notes: str = Field(max_length=10000)

    @field_validator("last_vaccination_date")
    @classmethod
    def timezone_required(cls, value):
        if value.tzinfo is None:
            raise ValueError("Include the date timezone")
        return value

    @field_validator("name")
    @classmethod
    def name_required(cls, value):
        if not value.strip():
            raise ValueError("Animal name cannot be blank")
        return value.strip()


class AnimalMutation(Input):
    mutation_id: UUID
    record_id: UUID
    base_revision: int = Field(ge=0)
    operation: Literal["upsert", "delete"]
    data: AnimalData | None = None

    @model_validator(mode="after")
    def check_payload(self):
        if (self.operation == "upsert") != (self.data is not None):
            raise ValueError("Only upsert requires animal data")
        return self


class Push(Input):
    mutations: list[AnimalMutation] = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def unique_mutations(self):
        if len({m.mutation_id for m in self.mutations}) != len(self.mutations):
            raise ValueError("Duplicate mutation IDs in batch")
        return self
