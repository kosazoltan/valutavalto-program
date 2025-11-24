CREATE EXTENSION IF NOT EXISTS vector;
-- pg_uuidv7 removed

-- CREATE EXTENSION "pg_uuidv7";
-- CREATE EXTENSION "pgvector";

create table documentgpt_vectors
(
    id        uuid,
    content   text,
    metadata  json,
    embedding vector(1536)
);



  DROP TABLE IF EXISTS "agreed_work_schedule";
  CREATE TABLE "agreed_work_schedule"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
   
    "work_section_length" SMALLINT DEFAULT NULL  	,	
   
    "rest_section_length" SMALLINT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "allowed_operation";
  CREATE TABLE "allowed_operation"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "authorization_id" uuid NOT NULL  	,	
   
    "operation_did" uuid NOT NULL  	,	
   
    "is_allowed" boolean NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "aml_check";
  CREATE TABLE "aml_check"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_id" uuid DEFAULT NULL  	,	
   
    "customer_id" uuid NOT NULL  	,	
   
    "check_date" timestamp NOT NULL  	,	
   
    "check_type_did" uuid NOT NULL  	,	
   
    "result_did" uuid NOT NULL  	,	
   
    "risk_level_did" uuid DEFAULT NULL  	,	
   
    "performed_by" uuid NOT NULL  	,	
   
    "notes" text DEFAULT NULL  	,	
   
    "require_approval" boolean NOT NULL  	,	
   
    "approved_by" uuid DEFAULT NULL  	,	
   
    "approval_date" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "assigned_role";
  CREATE TABLE "assigned_role"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "creator_ruser_id" uuid NOT NULL  	,	
   
    "role_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "assignment";
  CREATE TABLE "assignment"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "client_id" uuid NOT NULL  	,	
   
    "title" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR NOT NULL  	,	
   
    "pickup_location" VARCHAR NOT NULL  	,	
   
    "pickup_location_longitude" DECIMAL DEFAULT NULL  	,	
   
    "pickup_location_latitude" DECIMAL DEFAULT NULL  	,	
   
    "pickup_city" VARCHAR NOT NULL  	,	
   
    "pickup_state" uuid DEFAULT NULL  	,	
   
    "pickup_zip" VARCHAR NOT NULL  	,	
   
    "pickup_country_did" uuid NOT NULL  	,	
   
    "pickup_start_date" timestamp NOT NULL  	,	
   
    "pickup_end_date" timestamp NOT NULL  	,	
   
    "delivery_location" VARCHAR NOT NULL  	,	
   
    "delivery_location_longitude" DECIMAL DEFAULT NULL  	,	
   
    "delivery_location_latitude" DECIMAL DEFAULT NULL  	,	
   
    "delivery_city" VARCHAR NOT NULL  	,	
   
    "delivery_state" uuid DEFAULT NULL  	,	
   
    "delivery_zip" VARCHAR NOT NULL  	,	
   
    "delivery_country_did" uuid NOT NULL  	,	
   
    "delivery_start_date" timestamp NOT NULL  	,	
   
    "delivery_end_date" timestamp NOT NULL  	,	
   
    "cargo_type_did" uuid NOT NULL  	,	
   
    "weight" DECIMAL NOT NULL  	,	
   
    "volume" DECIMAL NOT NULL  	,	
   
    "special_handling_requirements" VARCHAR DEFAULT NULL  	,	
   
    "min_price" DECIMAL DEFAULT NULL  	,	
   
    "max_price" DECIMAL DEFAULT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "validity_start_date" timestamp NOT NULL  	,	
   
    "validity_end_date" timestamp NOT NULL  	,	
   
    "is_cooperative" boolean NOT NULL  	,	
   
    "assignment_status_did" uuid NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "published_at" timestamp DEFAULT NULL  	,	
   
    "completed_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "assignment_history";
  CREATE TABLE "assignment_history"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "assignment_id" uuid NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "changed_at" timestamp NOT NULL  	,	
   
    "changed_by_client_id" uuid DEFAULT NULL  	,	
   
    "changed_by_carrier_id" uuid DEFAULT NULL  	,	
   
    "changed_by_system" boolean NOT NULL  	,	
   
    "change_reason" VARCHAR DEFAULT NULL  	,	
   
    "change_details" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "assignment_search_template";
  CREATE TABLE "assignment_search_template"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrier_id" uuid NOT NULL  	,	
   
    "template_name" VARCHAR NOT NULL  	,	
   
    "search_parameters" VARCHAR NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "last_used_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "audit_log";
  CREATE TABLE "audit_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "timestamp" timestamp NOT NULL  	,	
   
    "action_type_did" uuid NOT NULL  	,	
   
    "entity_name" VARCHAR NOT NULL  	,	
   
    "entity_id" VARCHAR NOT NULL  	,	
   
    "worker_id" uuid DEFAULT NULL  	,	
   
    "branch_id" uuid DEFAULT NULL  	,	
   
    "old_value" TEXT DEFAULT NULL  	,	
   
    "new_value" TEXT DEFAULT NULL  	,	
   
    "ip_address" VARCHAR DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "authorization";
  CREATE TABLE "authorization"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "authorized_representative_id" uuid NOT NULL  	,	
   
    "authorization_type_did" uuid NOT NULL  	,	
   
    "issue_date" DATE NOT NULL  	,	
   
    "start_date" DATE NOT NULL  	,	
   
    "expiry_date" DATE DEFAULT NULL  	,	
   
    "max_amount" DECIMAL DEFAULT NULL  	,	
   
    "max_transaction_count" INT DEFAULT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "created_by" uuid NOT NULL  	,	
   
    "created_date" timestamp NOT NULL  	,	
   
    "verified_by" uuid DEFAULT NULL  	,	
   
    "verification_date" timestamp DEFAULT NULL  	,	
   
    "document_path" VARCHAR DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "authorized_representative";
  CREATE TABLE "authorized_representative"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "customer_id" uuid NOT NULL  	,	
   
    "first_name" VARCHAR NOT NULL  	,	
   
    "last_name" VARCHAR NOT NULL  	,	
   
    "birth_date" DATE DEFAULT NULL  	,	
   
    "identity_number" VARCHAR NOT NULL  	,	
   
    "identity_type_did" uuid NOT NULL  	,	
   
    "address" VARCHAR DEFAULT NULL  	,	
   
    "city" VARCHAR DEFAULT NULL  	,	
   
    "zip_code" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid DEFAULT NULL  	,	
   
    "phone" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR DEFAULT NULL  	,	
   
    "nationality_did" uuid DEFAULT NULL  	,	
   
    "is_pep" boolean NOT NULL  	,	
   
    "representative_type_did" uuid NOT NULL  	,	
   
    "relationship_did" uuid DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "balance_adjustment";
  CREATE TABLE "balance_adjustment"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "adjustment_date" timestamp NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity_change" INT NOT NULL  	,	
   
    "reason_did" uuid NOT NULL  	,	
   
    "performed_by" uuid NOT NULL  	,	
   
    "approved_by" uuid DEFAULT NULL  	,	
   
    "branch_transfer_id" uuid DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "band_exchange_rate_discount";
  CREATE TABLE "band_exchange_rate_discount"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "from_amount" DECIMAL NOT NULL  	,	
   
    "to_amount" DECIMAL NOT NULL  	,	
   
    "discount" DECIMAL NOT NULL  	,	
   
    "validation_date" timestamp NOT NULL  	,	
   
    "expiration_date" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "banknote_inventory";
  CREATE TABLE "banknote_inventory"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity" INT NOT NULL  	,	
   
    "last_updated" timestamp NOT NULL  	,	
   
    "branch_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch";
  CREATE TABLE "branch"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "bank_code" VARCHAR NOT NULL  	,	
   
    "branch_type_did" uuid NOT NULL  	,	
   
    "parent_branch_id" uuid DEFAULT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "address" VARCHAR NOT NULL  	,	
   
    "city" VARCHAR NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "phone" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR DEFAULT NULL  	,	
   
    "branch_status_did" uuid NOT NULL  	,	
   
    "opening_date" DATE NOT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_balance";
  CREATE TABLE "branch_balance"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "balance" DECIMAL NOT NULL  	,	
   
    "last_updated" timestamp NOT NULL  	,	
   
    "updated_by" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_calendar";
  CREATE TABLE "branch_calendar"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "calendar_id" uuid NOT NULL  	,	
   
    "is_open" boolean NOT NULL  	,	
   
    "opening_time" TIME DEFAULT NULL  	,	
   
    "closing_time" TIME DEFAULT NULL  	,	
   
    "day_type_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_calendar_exception";
  CREATE TABLE "branch_calendar_exception"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "calendar_id" uuid NOT NULL  	,	
   
    "exception_date" DATE NOT NULL  	,	
   
    "is_open" boolean NOT NULL  	,	
   
    "opening_time" TIME DEFAULT NULL  	,	
   
    "closing_time" TIME DEFAULT NULL  	,	
   
    "reason" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_exchange_rate";
  CREATE TABLE "branch_exchange_rate"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "exchange_rate_id" uuid NOT NULL  	,	
   
    "buy_rate_mod" DECIMAL DEFAULT NULL  	,	
   
    "mid_rate_mod" DECIMAL DEFAULT NULL  	,	
   
    "sell_rate_mod" DECIMAL DEFAULT NULL  	,	
   
    "buy_rate" DECIMAL DEFAULT NULL  	,	
   
    "mid_rate" DECIMAL DEFAULT NULL  	,	
   
    "sell_rate" DECIMAL DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "validation_date" timestamp NOT NULL  	,	
   
    "expiration_date" timestamp DEFAULT NULL  	,	
   
    "created_by" uuid NOT NULL  	,	
   
    "created_date" timestamp NOT NULL  	,	
   
    "updated_by" uuid DEFAULT NULL  	,	
   
    "updated_date" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_inventory";
  CREATE TABLE "branch_inventory"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity" INT NOT NULL  	,	
   
    "last_updated" timestamp NOT NULL  	,	
   
    "updated_by" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_inventory_log";
  CREATE TABLE "branch_inventory_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_session_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity_change" INT NOT NULL  	,	
   
    "timestamp" timestamp NOT NULL  	,	
   
    "transaction_id" uuid DEFAULT NULL  	,	
   
    "log_type_did" uuid NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_session";
  CREATE TABLE "branch_session"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "open_timestamp" timestamp NOT NULL  	,	
   
    "close_timestamp" timestamp DEFAULT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "initial_amount" DECIMAL NOT NULL  	,	
   
    "final_amount" DECIMAL DEFAULT NULL  	,	
   
    "base_currency_id" uuid NOT NULL  	,	
   
    "is_balanced" boolean DEFAULT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_transfer";
  CREATE TABLE "branch_transfer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transfer_number" VARCHAR NOT NULL  	,	
   
    "source_branch_id" uuid NOT NULL  	,	
   
    "target_branch_id" uuid NOT NULL  	,	
   
    "initiated_date" timestamp NOT NULL  	,	
   
    "initiated_by" uuid NOT NULL  	,	
   
    "planned_dispatch_date" timestamp NOT NULL  	,	
   
    "actual_dispatch_date" timestamp DEFAULT NULL  	,	
   
    "planned_arrival_date" timestamp NOT NULL  	,	
   
    "actual_arrival_date" timestamp DEFAULT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "security_company_id" uuid DEFAULT NULL  	,	
   
    "security_seal_number" VARCHAR DEFAULT NULL  	,	
   
    "transfer_reason_did" uuid NOT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_transfer_event";
  CREATE TABLE "branch_transfer_event"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_transfer_id" uuid NOT NULL  	,	
   
    "event_time" timestamp NOT NULL  	,	
   
    "event_type_did" uuid NOT NULL  	,	
   
    "location" VARCHAR DEFAULT NULL  	,	
   
    "performed_by" uuid NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "branch_transfer_item";
  CREATE TABLE "branch_transfer_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_transfer_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity_sent" INT NOT NULL  	,	
   
    "quantity_received" INT DEFAULT NULL  	,	
   
    "package_id" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "calendar";
  CREATE TABLE "calendar"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "day" DATE NOT NULL  	,	
   
    "day_of_week" INT NOT NULL  	,	
   
    "day_type_did" uuid NOT NULL  	,	
   
    "country_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "calendar_name_info";
  CREATE TABLE "calendar_name_info"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "year_day" INT DEFAULT NULL  	,	
   
    "name_info_id" uuid DEFAULT NULL  	,	
   
    "is_primary" boolean DEFAULT NULL  	,	
   
    "is_starred" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "car";
  CREATE TABLE "car"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "license_plate_number" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "chassis_number" VARCHAR DEFAULT NULL  	,	
   
    "motor_number" VARCHAR DEFAULT NULL  	,	
   
    "seats_number" SMALLINT NOT NULL  	,	
   
    "make" VARCHAR DEFAULT NULL  	,	
   
    "fuel" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrental";
  CREATE TABLE "carrental"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "short_name" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "company_form_did" uuid NOT NULL  	,	
   
    "partner_status_did" uuid NOT NULL  	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "tax_number" VARCHAR DEFAULT NULL  	,	
   
    "eu_tax_number" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrental_contact";
  CREATE TABLE "carrental_contact"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "contact_type_did" uuid NOT NULL  	,	
   
    "last_name" VARCHAR DEFAULT NULL  	,	
   
    "first_name" VARCHAR DEFAULT NULL  	,	
   
    "title" VARCHAR DEFAULT NULL  	,	
   
    "carrental_id" uuid NOT NULL  	,	
   
    "contact" VARCHAR NOT NULL  	,	
   
    "rank" SMALLINT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrental_contact_category";
  CREATE TABLE "carrental_contact_category"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrental_contact_id" uuid NOT NULL  	,	
   
    "category_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrental_contact_info";
  CREATE TABLE "carrental_contact_info"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrental_contact_id" uuid NOT NULL  	,	
   
    "contact_type_did" uuid NOT NULL  	,	
   
    "info" VARCHAR NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrier";
  CREATE TABLE "carrier"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "company_name" VARCHAR NOT NULL  	,	
   
    "tax_id" VARCHAR NOT NULL  	,	
   
    "fmcsa_license_number" VARCHAR NOT NULL  	,	
   
    "headquarters_address" VARCHAR NOT NULL  	,	
   
    "headquarters_address_longitude" DECIMAL DEFAULT NULL  	,	
   
    "headquarters_address_latitude" DECIMAL DEFAULT NULL  	,	
   
    "headquarters_city" VARCHAR NOT NULL  	,	
   
    "headquarters_state" uuid DEFAULT NULL  	,	
   
    "headquarters_zip" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "contact_name" VARCHAR NOT NULL  	,	
   
    "contact_email" VARCHAR NOT NULL  	,	
   
    "contact_phone" VARCHAR NOT NULL  	,	
   
    "carrier_competencies" VARCHAR DEFAULT NULL  	,	
   
    "operation_area" VARCHAR DEFAULT NULL  	,	
   
    "carrier_status_did" uuid NOT NULL  	,	
   
    "verification_date" timestamp DEFAULT NULL  	,	
   
    "verification_result" VARCHAR DEFAULT NULL  	,	
   
    "verified_by" VARCHAR DEFAULT NULL  	,	
   
    "registration_date" timestamp NOT NULL  	,	
   
    "last_login_date" timestamp DEFAULT NULL  	,	
   
    "average_rating" DECIMAL DEFAULT NULL  	,	
   
    "rating_count" INT DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "carrier_location";
  CREATE TABLE "carrier_location"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrier_id" uuid NOT NULL  	,	
   
    "location_name" VARCHAR DEFAULT NULL  	,	
   
    "address" VARCHAR NOT NULL  	,	
   
    "address_longitude" DECIMAL DEFAULT NULL  	,	
   
    "address_latitude" DECIMAL DEFAULT NULL  	,	
   
    "city" VARCHAR NOT NULL  	,	
   
    "state" uuid DEFAULT NULL  	,	
   
    "zip" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "is_primary" boolean NOT NULL  	,	
   
    "location_type" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "cash_transfer";
  CREATE TABLE "cash_transfer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "source_branch_id" uuid NOT NULL  	,	
   
    "target_branch_id" uuid NOT NULL  	,	
   
    "initiator_worker_id" uuid NOT NULL  	,	
   
    "recipient_worker_id" uuid DEFAULT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "amount" DECIMAL NOT NULL  	,	
   
    "transfer_date" timestamp NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "cash_transfer_detail";
  CREATE TABLE "cash_transfer_detail"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "cash_transfer_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity" INT NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "category";
  CREATE TABLE "category"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "category_group_did" uuid NOT NULL  	,	
   
    "category" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "client";
  CREATE TABLE "client"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "is_company" boolean NOT NULL  	,	
   
    "company_name" VARCHAR DEFAULT NULL  	,	
   
    "tax_id" VARCHAR DEFAULT NULL  	,	
   
    "full_name" VARCHAR DEFAULT NULL  	,	
   
    "ssn" VARCHAR DEFAULT NULL  	,	
   
    "address" VARCHAR NOT NULL  	,	
   
    "address_longitude" DECIMAL DEFAULT NULL  	,	
   
    "address_latitude" DECIMAL DEFAULT NULL  	,	
   
    "city" VARCHAR NOT NULL  	,	
   
    "state" uuid DEFAULT NULL  	,	
   
    "zip" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "contact_name" VARCHAR DEFAULT NULL  	,	
   
    "contact_email" VARCHAR NOT NULL  	,	
   
    "contact_phone" VARCHAR NOT NULL  	,	
   
    "client_status_did" uuid NOT NULL  	,	
   
    "verification_date" timestamp DEFAULT NULL  	,	
   
    "verification_result" VARCHAR DEFAULT NULL  	,	
   
    "verified_by" VARCHAR DEFAULT NULL  	,	
   
    "registration_date" timestamp NOT NULL  	,	
   
    "last_login_date" timestamp DEFAULT NULL  	,	
   
    "average_rating" DECIMAL DEFAULT NULL  	,	
   
    "rating_count" INT DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "closing_detail";
  CREATE TABLE "closing_detail"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "daily_closing_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "expected_quantity" INT NOT NULL  	,	
   
    "actual_quantity" INT NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "closure";
  CREATE TABLE "closure"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "inst_loc_id" uuid DEFAULT NULL  	,	
   
    "project_id" uuid DEFAULT NULL  	,	
   
    "closure_date" DATE NOT NULL  	,	
   
    "closure_status_did" uuid NOT NULL  	,	
   
    "invoice_out_id" uuid DEFAULT NULL  	,	
   
    "margin" DECIMAL DEFAULT NULL  	,	
   
    "hourly_rate" DECIMAL DEFAULT NULL  	,	
   
    "distance_fee" DECIMAL DEFAULT NULL  	,	
   
    "departure_fee" DECIMAL DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "closure_item";
  CREATE TABLE "closure_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "closure_id" uuid NOT NULL  	,	
   
    "worksheet_id" uuid NOT NULL  	,	
   
    "closure_item_type_did" uuid NOT NULL  	,	
   
    "worksheet_worker_id" uuid DEFAULT NULL  	,	
   
    "worksheet_material_id" uuid DEFAULT NULL  	,	
   
    "price" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "invoice_out_item_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "commission";
  CREATE TABLE "commission"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "offer_id" uuid NOT NULL  	,	
   
    "carrier_id" uuid NOT NULL  	,	
   
    "amount" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "commission_rate_id" uuid NOT NULL  	,	
   
    "calculation_details" VARCHAR DEFAULT NULL  	,	
   
    "invoice_id" VARCHAR DEFAULT NULL  	,	
   
    "invoice_date" DATE DEFAULT NULL  	,	
   
    "due_date" DATE DEFAULT NULL  	,	
   
    "payment_date" DATE DEFAULT NULL  	,	
   
    "payment_method_did" uuid DEFAULT NULL  	,	
   
    "payment_reference" VARCHAR DEFAULT NULL  	,	
   
    "commission_status_did" uuid NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "commission_rate";
  CREATE TABLE "commission_rate"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "rate_type_did" uuid NOT NULL  	,	
   
    "fixed_amount" DECIMAL DEFAULT NULL  	,	
   
    "percentage_rate" DECIMAL DEFAULT NULL  	,	
   
    "min_amount" DECIMAL DEFAULT NULL  	,	
   
    "max_amount" DECIMAL DEFAULT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "valid_from" DATE NOT NULL  	,	
   
    "valid_to" DATE DEFAULT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "company";
  CREATE TABLE "company"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "short_name" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "company_form_did" uuid NOT NULL  	,	
   
    "group_code" VARCHAR DEFAULT NULL  	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR NOT NULL  	,	
   
    "phone" VARCHAR NOT NULL  	,	
   
    "tax_number" VARCHAR DEFAULT NULL  	,	
   
    "eu_tax_number" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
   
    "inv_country_did" uuid NOT NULL  	,	
   
    "inv_zip_code" VARCHAR NOT NULL  	,	
   
    "inv_settlement" VARCHAR NOT NULL  	,	
   
    "inv_street_house" VARCHAR NOT NULL  	,	
   
    "mail_country_did" uuid NOT NULL  	,	
   
    "mail_zip_code" VARCHAR NOT NULL  	,	
   
    "mail_settlement" VARCHAR NOT NULL  	,	
   
    "mail_street_house" VARCHAR NOT NULL  	,	
   
    "margin" DECIMAL NOT NULL  	,	
   
    "hourly_rate" DECIMAL NOT NULL  	,	
   
    "distance_fee" DECIMAL NOT NULL  	,	
   
    "departure_fee" DECIMAL NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "base_company" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "company_bank_account";
  CREATE TABLE "company_bank_account"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "address" VARCHAR DEFAULT NULL  	,	
   
    "swift" VARCHAR DEFAULT NULL  	,	
   
    "huf_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "huf_iban" VARCHAR DEFAULT NULL  	,	
   
    "dev_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "dev_iban" VARCHAR DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "bank_account_status_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "complaint";
  CREATE TABLE "complaint"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "client_id" uuid DEFAULT NULL  	,	
   
    "carrier_id" uuid DEFAULT NULL  	,	
   
    "assignment_id" uuid DEFAULT NULL  	,	
   
    "offer_id" uuid DEFAULT NULL  	,	
   
    "complaint_type_did" uuid NOT NULL  	,	
   
    "complaint_status_did" uuid NOT NULL  	,	
   
    "priority_did" uuid NOT NULL  	,	
   
    "title" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "assigned_to" VARCHAR DEFAULT NULL  	,	
   
    "assigned_at" timestamp DEFAULT NULL  	,	
   
    "resolved_at" timestamp DEFAULT NULL  	,	
   
    "resolution" VARCHAR DEFAULT NULL  	,	
   
    "closed_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "contract";
  CREATE TABLE "contract"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "site_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE NOT NULL  	,	
   
    "valid_to_date" DATE NOT NULL  	,	
   
    "contract_date" DATE DEFAULT NULL  	,	
   
    "contract_status_did" uuid NOT NULL  	,	
   
    "settlement_basis_did" uuid DEFAULT NULL  	,	
   
    "settlement_frequency_did" uuid DEFAULT NULL  	,	
   
    "payment_deadline" SMALLINT DEFAULT NULL  	,	
   
    "technical_content" text DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "cooperative_assignment_part";
  CREATE TABLE "cooperative_assignment_part"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "assignment_id" uuid NOT NULL  	,	
   
    "carrier_id" uuid DEFAULT NULL  	,	
   
    "part_name" VARCHAR NOT NULL  	,	
   
    "part_description" VARCHAR DEFAULT NULL  	,	
   
    "weight_portion" DECIMAL NOT NULL  	,	
   
    "volume_portion" DECIMAL NOT NULL  	,	
   
    "price" DECIMAL DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "part_status_did" uuid NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "currency";
  CREATE TABLE "currency"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "symbol" VARCHAR DEFAULT NULL  	,	
   
    "is_base" boolean NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "currency_status_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "currency_denomination";
  CREATE TABLE "currency_denomination"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "denomination" DECIMAL NOT NULL  	,	
   
    "is_coin" boolean NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "sorting_order" INT NOT NULL  	,	
   
    "availability_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "customer";
  CREATE TABLE "customer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "customer_type_did" uuid NOT NULL  	,	
   
    "first_name" VARCHAR NOT NULL  	,	
   
    "last_name" VARCHAR NOT NULL  	,	
   
    "birth_date" DATE NOT NULL  	,	
   
    "identity_number" VARCHAR NOT NULL  	,	
   
    "identity_type_did" uuid NOT NULL  	,	
   
    "address" VARCHAR NOT NULL  	,	
   
    "city" VARCHAR NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "phone" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR DEFAULT NULL  	,	
   
    "registration_date" DATE NOT NULL  	,	
   
    "nationality_did" uuid NOT NULL  	,	
   
    "is_pep" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "daily_closing";
  CREATE TABLE "daily_closing"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "closing_date" DATE NOT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "opening_cash" DECIMAL NOT NULL  	,	
   
    "closing_cash" DECIMAL NOT NULL  	,	
   
    "total_transactions" INT NOT NULL  	,	
   
    "total_buy_volume" DECIMAL NOT NULL  	,	
   
    "total_sell_volume" DECIMAL NOT NULL  	,	
   
    "total_fees" DECIMAL NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
   
    "closing_time" timestamp NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "delivery_note";
  CREATE TABLE "delivery_note"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "invoice_create_date" DATE NOT NULL  	,	
   
    "invoice_no" VARCHAR NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "language_did" uuid DEFAULT NULL  	,	
   
    "completion_date" DATE NOT NULL  	,	
   
    "payment_deadline" DATE NOT NULL  	,	
   
    "payment_date" DATE DEFAULT NULL  	,	
   
    "payment_note" VARCHAR DEFAULT NULL  	,	
   
    "payment_status_did" uuid NOT NULL  	,	
   
    "processing_status_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "delivery_note_item";
  CREATE TABLE "delivery_note_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "delivery_note_id" uuid NOT NULL  	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_price" DECIMAL NOT NULL  	,	
   
    "vat_rate" DECIMAL NOT NULL  	,	
   
    "net_amount" DECIMAL NOT NULL  	,	
   
    "vat_amount" DECIMAL NOT NULL  	,	
   
    "gross_amount" DECIMAL NOT NULL  	,	
   
    "expiry_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "demand";
  CREATE TABLE "demand"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "contract_id" uuid NOT NULL  	,	
   
    "demand_status_did" uuid NOT NULL  	,	
   
    "task_type_did" uuid DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "begin_date" DATE DEFAULT NULL  	,	
   
    "end_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "demand_item";
  CREATE TABLE "demand_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "demand_id" uuid NOT NULL  	,	
   
    "hall_id" uuid DEFAULT NULL  	,	
   
    "begin_date" DATE NOT NULL  	,	
   
    "end_date" DATE DEFAULT NULL  	,	
   
    "head" SMALLINT DEFAULT NULL  	,	
   
    "work_clothes_provided_flag" boolean DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "denomination_optimization";
  CREATE TABLE "denomination_optimization"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "strategy_did" uuid NOT NULL  	,	
   
    "priority_order" VARCHAR DEFAULT NULL  	,	
   
    "min_coins" boolean NOT NULL  	,	
   
    "min_banknotes" boolean NOT NULL  	,	
   
    "min_total_count" boolean NOT NULL  	,	
   
    "is_default" boolean NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "denomination_rule";
  CREATE TABLE "denomination_rule"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "rule_type_did" uuid NOT NULL  	,	
   
    "rule_name" VARCHAR NOT NULL  	,	
   
    "min_amount" DECIMAL DEFAULT NULL  	,	
   
    "max_amount" DECIMAL DEFAULT NULL  	,	
   
    "rule_config" VARCHAR NOT NULL  	,	
   
    "branch_id" uuid DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "optimization_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "denomination_transaction_log";
  CREATE TABLE "denomination_transaction_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_id" uuid NOT NULL  	,	
   
    "request_amount" DECIMAL NOT NULL  	,	
   
    "actual_amount" DECIMAL NOT NULL  	,	
   
    "request_config" VARCHAR DEFAULT NULL  	,	
   
    "response_config" VARCHAR NOT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "rule_id" uuid DEFAULT NULL  	,	
   
    "optimization_id" uuid DEFAULT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "manual_override" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "dictionary";
  CREATE TABLE "dictionary"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code_type_did" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "note" TEXT DEFAULT NULL  	,	
   
    "seq" SMALLINT DEFAULT NULL  	,	
   
    "contr_code" VARCHAR DEFAULT NULL  	,	
   
    "code" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "dictionary_language";
  CREATE TABLE "dictionary_language"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "dictionary_id" uuid NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "note" TEXT DEFAULT NULL  	,	
   
    "language_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "dictionary_relation";
  CREATE TABLE "dictionary_relation"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code_type_1_did" uuid NOT NULL  	,	
   
    "code_type_2_did" uuid NOT NULL  	,	
   
    "relation_type_did" uuid NOT NULL  	,	
   
    "valid_from_dt" timestamp DEFAULT NULL  	,	
   
    "valid_to_dt" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "dictionary_validity";
  CREATE TABLE "dictionary_validity"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "dictionary_id" uuid NOT NULL  	,	
   
    "valid_from_dt" timestamp DEFAULT NULL  	,	
   
    "valid_to_dt" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "document";
  CREATE TABLE "document"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "cgroup" VARCHAR NOT NULL  	,	
   
    "cid" VARCHAR NOT NULL  	,	
   
    "document_rule_id" uuid NOT NULL  	,	
   
    "document_number" VARCHAR DEFAULT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "document_id" uuid DEFAULT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "date_of_signature" DATE DEFAULT NULL  	,	
   
    "country_did" uuid DEFAULT NULL  	,	
   
    "language_did" uuid DEFAULT NULL  	,	
   
    "document_status_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "document_rule";
  CREATE TABLE "document_rule"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "document_rule_id" uuid DEFAULT NULL  	,	
   
    "subject_did" uuid DEFAULT NULL  	,	
   
    "obligation_did" uuid DEFAULT NULL  	,	
   
    "validity_type_did" uuid DEFAULT NULL  	,	
   
    "validity" VARCHAR DEFAULT NULL  	,	
   
    "notification_before_expiry" SMALLINT DEFAULT NULL  	,	
   
    "template" BIGINT DEFAULT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
   
    "interpretable_attributes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "elementary_right";
  CREATE TABLE "elementary_right"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "only_locally" boolean DEFAULT NULL  	,	
   
    "external_user_issued" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "elementary_right_parameter_type";
  CREATE TABLE "elementary_right_parameter_type"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "elementary_right_id" uuid NOT NULL  	,	
   
    "right_parameter_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "email";
  CREATE TABLE "email"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "email_uid" VARCHAR NOT NULL  	,	
   
    "recv_date" timestamp NOT NULL  	,	
   
    "sender" VARCHAR NOT NULL  	,	
   
    "recipients" VARCHAR NOT NULL  	,	
   
    "subject" VARCHAR NOT NULL  	,	
   
    "content" bytea DEFAULT NULL  	,	
   
    "task_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "exchange_rate";
  CREATE TABLE "exchange_rate"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "rate_date" DATE NOT NULL  	,	
   
    "buy_rate" DECIMAL NOT NULL  	,	
   
    "mid_rate" DECIMAL NOT NULL  	,	
   
    "sell_rate" DECIMAL NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "validation_date" timestamp NOT NULL  	,	
   
    "expiration_date" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "exchange_rate_source";
  CREATE TABLE "exchange_rate_source"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "api_url" VARCHAR DEFAULT NULL  	,	
   
    "api_key" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "update_freq" INT NOT NULL  	,	
   
    "last_update" timestamp DEFAULT NULL  	,	
   
    "priority" SMALLINT NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "figdef";
  CREATE TABLE "figdef"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "label" VARCHAR NOT NULL  	,	
   
    "figdef_id" uuid DEFAULT NULL  	,	
   
    "visible" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "file";
  CREATE TABLE "file"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "document_id" uuid NOT NULL  	,	
   
    "file_name" VARCHAR NOT NULL  	,	
   
    "file_datetime" timestamp NOT NULL  	,	
   
    "mime_type" VARCHAR NOT NULL  	,	
   
    "file_size" BIGINT NOT NULL  	,	
   
    "file_content" bytea NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "food_inventory";
  CREATE TABLE "food_inventory"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "expiry_date" DATE NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_price" DECIMAL DEFAULT NULL  	,	
   
    "received_date" DATE DEFAULT NULL  	,	
   
    "reserved_quantity" DECIMAL DEFAULT NULL  	,	
   
    "available_quantity" DECIMAL DEFAULT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "food_order";
  CREATE TABLE "food_order"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "order_date" DATE NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "expected_price" DECIMAL DEFAULT NULL  	,	
   
    "priority_did" uuid NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "expected_delivery" DATE DEFAULT NULL  	,	
   
    "actual_delivery" DATE DEFAULT NULL  	,	
   
    "delivered_quantity" DECIMAL DEFAULT NULL  	,	
   
    "actual_price" DECIMAL DEFAULT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "food_pricing";
  CREATE TABLE "food_pricing"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "partner_id" uuid DEFAULT NULL  	,	
   
    "price_type_did" uuid NOT NULL  	,	
   
    "base_price" DECIMAL NOT NULL  	,	
   
    "discount_percentage" DECIMAL DEFAULT NULL  	,	
   
    "discount_amount" DECIMAL DEFAULT NULL  	,	
   
    "final_price" DECIMAL NOT NULL  	,	
   
    "valid_from" DATE NOT NULL  	,	
   
    "valid_to" DATE DEFAULT NULL  	,	
   
    "active_flag" boolean NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "hall";
  CREATE TABLE "hall"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "site_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "inst_loc";
  CREATE TABLE "inst_loc"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "inst_loc_code" VARCHAR NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
   
    "spec_access" VARCHAR DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_group";
  CREATE TABLE "invoice_group"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "year" SMALLINT NOT NULL  	,	
   
    "prefix" VARCHAR NOT NULL  	,	
   
    "counter" INT NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_in";
  CREATE TABLE "invoice_in"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "invoice_create_date" DATE NOT NULL  	,	
   
    "invoice_no" VARCHAR NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "language_did" uuid DEFAULT NULL  	,	
   
    "completion_date" DATE DEFAULT NULL  	,	
   
    "payment_deadline" DATE DEFAULT NULL  	,	
   
    "payment_date" DATE DEFAULT NULL  	,	
   
    "payment_note" VARCHAR DEFAULT NULL  	,	
   
    "payment_status_did" uuid NOT NULL  	,	
   
    "processing_status_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_in_item";
  CREATE TABLE "invoice_in_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "invoice_in_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "material_id" uuid DEFAULT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "unit_price" DECIMAL NOT NULL  	,	
   
    "net_price" DECIMAL NOT NULL  	,	
   
    "vat_rate" DECIMAL NOT NULL  	,	
   
    "vat_amount" DECIMAL NOT NULL  	,	
   
    "gross_amount" DECIMAL NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_in_item_mat_warehouse";
  CREATE TABLE "invoice_in_item_mat_warehouse"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "invoice_in_item_id" uuid NOT NULL  	,	
   
    "mat_warehouse_id" uuid NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "leased_device" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_out";
  CREATE TABLE "invoice_out"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "project_id" uuid NOT NULL  	,	
   
    "settlement_id" uuid NOT NULL  	,	
   
    "invoice_no" VARCHAR NOT NULL  	,	
   
    "invoice_state_did" uuid NOT NULL  	,	
   
    "invoice_type_did" uuid NOT NULL  	,	
   
    "payment_method_did" uuid NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "language_did" uuid NOT NULL  	,	
   
    "created_at" timestamp DEFAULT NULL  	,	
   
    "created_by" uuid DEFAULT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "updated_by" uuid DEFAULT NULL  	,	
   
    "completion_date" DATE NOT NULL  	,	
   
    "payment_deadline" DATE NOT NULL  	,	
   
    "payment_date" DATE DEFAULT NULL  	,	
   
    "payment_note" VARCHAR DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "compl_begin_date" DATE DEFAULT NULL  	,	
   
    "compl_end_date" DATE DEFAULT NULL  	,	
   
    "periodic_accounting" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "invoice_out_item";
  CREATE TABLE "invoice_out_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "invoice_out_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "unit_price" DECIMAL NOT NULL  	,	
   
    "net_price" DECIMAL NOT NULL  	,	
   
    "vat_rate" DECIMAL NOT NULL  	,	
   
    "vat_amount" DECIMAL NOT NULL  	,	
   
    "gross_amount" DECIMAL NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "l2f_notification";
  CREATE TABLE "l2f_notification"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "client_id" uuid DEFAULT NULL  	,	
   
    "carrier_id" uuid DEFAULT NULL  	,	
   
    "l2f_notification_type_did" uuid NOT NULL  	,	
   
    "notification_status_did" uuid NOT NULL  	,	
   
    "channel_did" uuid NOT NULL  	,	
   
    "title" VARCHAR NOT NULL  	,	
   
    "content" VARCHAR NOT NULL  	,	
   
    "reference_id" VARCHAR DEFAULT NULL  	,	
   
    "reference_type" VARCHAR DEFAULT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "sent_at" timestamp DEFAULT NULL  	,	
   
    "delivered_at" timestamp DEFAULT NULL  	,	
   
    "read_at" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "l2f_system_parameter";
  CREATE TABLE "l2f_system_parameter"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "parameter_key" VARCHAR NOT NULL  	,	
   
    "parameter_value" VARCHAR NOT NULL  	,	
   
    "parameter_type_did" uuid NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "is_encrypted" boolean NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "updated_by" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "limit_setting";
  CREATE TABLE "limit_setting"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "limit_type_did" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "amount" DECIMAL NOT NULL  	,	
   
    "period_did" uuid DEFAULT NULL  	,	
   
    "branch_id" uuid DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "approval_level_did" uuid DEFAULT NULL  	,	
   
    "start_date" DATE NOT NULL  	,	
   
    "end_date" DATE DEFAULT NULL  	,	
   
    "created_by" uuid NOT NULL  	,	
   
    "created_date" timestamp NOT NULL  	,	
   
    "updated_by" uuid DEFAULT NULL  	,	
   
    "updated_date" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_order_in";
  CREATE TABLE "mat_order_in"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "expected_date" DATE NOT NULL  	,	
   
    "order_date" DATE DEFAULT NULL  	,	
   
    "order_status_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_order_in_item";
  CREATE TABLE "mat_order_in_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "mat_order_in_id" uuid NOT NULL  	,	
   
    "material_id" uuid NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_procurement";
  CREATE TABLE "mat_procurement"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "material_id" uuid NOT NULL  	,	
   
    "invoice_in_item_id" uuid NOT NULL  	,	
   
    "purchase_price_netto" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "sales_price_netto" DECIMAL NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "stock_quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_stock";
  CREATE TABLE "mat_stock"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "material_id" uuid NOT NULL  	,	
   
    "mat_warehouse_id" uuid NOT NULL  	,	
   
    "mat_procurement_id" uuid DEFAULT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_stock_movement";
  CREATE TABLE "mat_stock_movement"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "material_id" uuid NOT NULL  	,	
   
    "mat_warehouse_id" uuid NOT NULL  	,	
   
    "movement_date" timestamp NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "source_mat_warehouse_id" uuid DEFAULT NULL  	,	
   
    "destination_mat_warehouse_id" uuid DEFAULT NULL  	,	
   
    "movement_type_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "mat_warehouse";
  CREATE TABLE "mat_warehouse"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "project_id" uuid DEFAULT NULL  	,	
   
    "base_warehouse" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "material";
  CREATE TABLE "material"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "manufacturer" VARCHAR DEFAULT NULL  	,	
   
    "article_number" VARCHAR NOT NULL  	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "category" VARCHAR DEFAULT NULL  	,	
   
    "partner_id" uuid DEFAULT NULL  	,	
   
    "material_supplier_url" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "material_list_price";
  CREATE TABLE "material_list_price"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "material_id" uuid NOT NULL  	,	
   
    "list_price_date" DATE NOT NULL  	,	
   
    "list_price_netto" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "medical_exam";
  CREATE TABLE "medical_exam"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "medical_exam_status_did" uuid NOT NULL  	,	
   
    "deadline_date" DATE NOT NULL  	,	
   
    "examination_date" DATE DEFAULT NULL  	,	
   
    "medical_exam_result_did" uuid DEFAULT NULL  	,	
   
    "restriction" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "menu";
  CREATE TABLE "menu"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "superior" VARCHAR DEFAULT NULL  	,	
   
    "superscription" VARCHAR DEFAULT NULL  	,	
   
    "help" VARCHAR DEFAULT NULL  	,	
   
    "status" VARCHAR NOT NULL  	,	
   
    "seq" SMALLINT DEFAULT NULL  	,	
   
    "path" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "menu_access_right";
  CREATE TABLE "menu_access_right"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "elementary_right_id" uuid NOT NULL  	,	
   
    "menu_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "name_day";
  CREATE TABLE "name_day"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "first_name" VARCHAR NOT NULL  	,	
   
    "name_day" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "name_info";
  CREATE TABLE "name_info"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "first_name" TEXT DEFAULT NULL  	,	
   
    "unaccented_name" TEXT DEFAULT NULL  	,	
   
    "commonness" INT DEFAULT NULL  	,	
   
    "gender" INT DEFAULT NULL  	,	
   
    "origin" TEXT DEFAULT NULL  	,	
   
    "nicknames" TEXT DEFAULT NULL  	,	
   
    "related_names" TEXT DEFAULT NULL  	,	
   
    "opposite_names" TEXT DEFAULT NULL  	,	
   
    "foreign_names" TEXT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "newsletter";
  CREATE TABLE "newsletter"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "newsletter_type_did" uuid NOT NULL  	,	
   
    "newsletter_status_did" uuid NOT NULL  	,	
   
    "title" VARCHAR NOT NULL  	,	
   
    "content" VARCHAR NOT NULL  	,	
   
    "target_carriers" boolean NOT NULL  	,	
   
    "target_clients" boolean NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "created_by" VARCHAR NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "scheduled_at" timestamp DEFAULT NULL  	,	
   
    "sent_at" timestamp DEFAULT NULL  	,	
   
    "recipient_count" INT DEFAULT NULL  	,	
   
    "open_count" INT DEFAULT NULL  	,	
   
    "click_count" INT DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "notification";
  CREATE TABLE "notification"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "notification_type_did" uuid NOT NULL  	,	
   
    "message" VARCHAR NOT NULL  	,	
   
    "creation_date" timestamp NOT NULL  	,	
   
    "read_date" timestamp DEFAULT NULL  	,	
   
    "is_read" boolean NOT NULL  	,	
   
    "priority_did" uuid NOT NULL  	,	
   
    "related_entity" VARCHAR DEFAULT NULL  	,	
   
    "related_id" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "offer";
  CREATE TABLE "offer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "assignment_id" uuid NOT NULL  	,	
   
    "carrier_id" uuid NOT NULL  	,	
   
    "cooperative_assignment_part_id" uuid DEFAULT NULL  	,	
   
    "price" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "delivery_conditions" VARCHAR DEFAULT NULL  	,	
   
    "validity_start_date" timestamp NOT NULL  	,	
   
    "validity_end_date" timestamp NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
   
    "offer_status_did" uuid NOT NULL  	,	
   
    "created_at" timestamp NOT NULL  	,	
   
    "updated_at" timestamp DEFAULT NULL  	,	
   
    "submitted_at" timestamp DEFAULT NULL  	,	
   
    "evaluated_at" timestamp DEFAULT NULL  	,	
   
    "evaluated_by" uuid DEFAULT NULL  	,	
   
    "evaluation_notes" VARCHAR DEFAULT NULL  	,	
   
    "confirmed_at" timestamp DEFAULT NULL  	,	
   
    "commission_amount" DECIMAL DEFAULT NULL  	,	
   
    "commission_paid_at" timestamp DEFAULT NULL  	,	
   
    "invoice_id" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "offer_history";
  CREATE TABLE "offer_history"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "offer_id" uuid NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "changed_at" timestamp NOT NULL  	,	
   
    "changed_by_client_id" uuid DEFAULT NULL  	,	
   
    "changed_by_carrier_id" uuid DEFAULT NULL  	,	
   
    "changed_by_system" boolean NOT NULL  	,	
   
    "change_reason" VARCHAR DEFAULT NULL  	,	
   
    "change_details" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "offer_modification_request";
  CREATE TABLE "offer_modification_request"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "offer_id" uuid NOT NULL  	,	
   
    "client_id" uuid NOT NULL  	,	
   
    "requested_at" timestamp NOT NULL  	,	
   
    "request_description" VARCHAR NOT NULL  	,	
   
    "suggested_price" DECIMAL DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "suggested_conditions" VARCHAR DEFAULT NULL  	,	
   
    "response_deadline" timestamp NOT NULL  	,	
   
    "responded_at" timestamp DEFAULT NULL  	,	
   
    "response_type_did" uuid DEFAULT NULL  	,	
   
    "response_notes" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "order_in";
  CREATE TABLE "order_in"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "order_date" DATE DEFAULT NULL  	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "ordered_quantity" DECIMAL NOT NULL  	,	
   
    "shipped_quantity" DECIMAL NOT NULL  	,	
   
    "order_status_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "order_out";
  CREATE TABLE "order_out"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "order_dt" DATE NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "order_out_item";
  CREATE TABLE "order_out_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "order_out_id" uuid NOT NULL  	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_price" DECIMAL NOT NULL  	,	
   
    "vat_rate_did" uuid NOT NULL  	,	
   
    "net_amount" DECIMAL NOT NULL  	,	
   
    "vat_amount" DECIMAL NOT NULL  	,	
   
    "gross_amount" DECIMAL NOT NULL  	,	
   
    "order_status_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "own_contact";
  CREATE TABLE "own_contact"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "package_material";
  CREATE TABLE "package_material"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "partner";
  CREATE TABLE "partner"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "short_name" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "company_form_did" uuid DEFAULT NULL  	,	
   
    "partner_role_did" uuid NOT NULL  	,	
   
    "partner_status_did" uuid NOT NULL  	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "tax_number" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
   
    "inv_country_did" uuid NOT NULL  	,	
   
    "inv_zip_code" VARCHAR NOT NULL  	,	
   
    "inv_settlement" VARCHAR NOT NULL  	,	
   
    "inv_street_house" VARCHAR NOT NULL  	,	
   
    "mail_country_did" uuid NOT NULL  	,	
   
    "mail_zip_code" VARCHAR NOT NULL  	,	
   
    "mail_settlement" VARCHAR NOT NULL  	,	
   
    "mail_street_house" VARCHAR NOT NULL  	,	
   
    "iban" VARCHAR DEFAULT NULL  	,	
   
    "swift" VARCHAR DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "payment_method_did" uuid DEFAULT NULL  	,	
   
    "day_to_payment" SMALLINT DEFAULT NULL  	,	
   
    "legal_representative" VARCHAR DEFAULT NULL  	,	
   
    "phone" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR DEFAULT NULL  	,	
   
    "margin" DECIMAL DEFAULT NULL  	,	
   
    "hourly_rate" DECIMAL DEFAULT NULL  	,	
   
    "distance_fee" DECIMAL DEFAULT NULL  	,	
   
    "departure_fee" DECIMAL DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "partner_bank_account";
  CREATE TABLE "partner_bank_account"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "address" VARCHAR DEFAULT NULL  	,	
   
    "swift" VARCHAR DEFAULT NULL  	,	
   
    "huf_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "huf_iban" VARCHAR DEFAULT NULL  	,	
   
    "dev_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "dev_iban" VARCHAR DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "bank_account_status_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "partner_contact";
  CREATE TABLE "partner_contact"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "contact_type_did" uuid NOT NULL  	,	
   
    "last_name" VARCHAR DEFAULT NULL  	,	
   
    "first_name" VARCHAR DEFAULT NULL  	,	
   
    "title" VARCHAR DEFAULT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "site_id" uuid DEFAULT NULL  	,	
   
    "contact" VARCHAR NOT NULL  	,	
   
    "rank" SMALLINT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "partner_contact_category";
  CREATE TABLE "partner_contact_category"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_contact_id" uuid NOT NULL  	,	
   
    "category_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "partner_contact_info";
  CREATE TABLE "partner_contact_info"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_contact_id" uuid NOT NULL  	,	
   
    "contact_type_did" uuid NOT NULL  	,	
   
    "info" VARCHAR NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "password_log";
  CREATE TABLE "password_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid DEFAULT NULL  	,	
   
    "old_password" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "person";
  CREATE TABLE "person"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "citizenship_1_did" uuid NOT NULL  	,	
   
    "citizenship_2_did" uuid DEFAULT NULL  	,	
   
    "last_name" VARCHAR NOT NULL  	,	
   
    "first_name" VARCHAR NOT NULL  	,	
   
    "uniquemark" VARCHAR DEFAULT NULL  	,	
   
    "title" VARCHAR DEFAULT NULL  	,	
   
    "birth_last_name" VARCHAR DEFAULT NULL  	,	
   
    "birth_first_name" VARCHAR DEFAULT NULL  	,	
   
    "birth_date" DATE NOT NULL  	,	
   
    "birthplace" VARCHAR NOT NULL  	,	
   
    "birthday_notification_flag" boolean DEFAULT NULL  	,	
   
    "name_day_notification_flag" boolean DEFAULT NULL  	,	
   
    "mothers_name" VARCHAR NOT NULL  	,	
   
    "disabled_flag" boolean DEFAULT NULL  	,	
   
    "pension_flag" boolean DEFAULT NULL  	,	
   
    "shoe_size" VARCHAR DEFAULT NULL  	,	
   
    "pants_size" VARCHAR DEFAULT NULL  	,	
   
    "upper_part_size" VARCHAR DEFAULT NULL  	,	
   
    "cap_size" VARCHAR DEFAULT NULL  	,	
   
    "glove_size" VARCHAR DEFAULT NULL  	,	
   
    "without_address_flag" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "person_address";
  CREATE TABLE "person_address"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "person_id" uuid NOT NULL  	,	
   
    "address_type_did" uuid NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "person_contact";
  CREATE TABLE "person_contact"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "contact_type_did" uuid NOT NULL  	,	
   
    "person_id" uuid NOT NULL  	,	
   
    "contact" VARCHAR NOT NULL  	,	
   
    "rank" SMALLINT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "person_name_day";
  CREATE TABLE "person_name_day"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "person_id" uuid NOT NULL  	,	
   
    "name_day_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "person_qualification";
  CREATE TABLE "person_qualification"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "person_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "date_of_acquisition" DATE DEFAULT NULL  	,	
   
    "educational_institution" VARCHAR DEFAULT NULL  	,	
   
    "qualification" VARCHAR DEFAULT NULL  	,	
   
    "education_degree" VARCHAR DEFAULT NULL  	,	
   
    "validity_type_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "position_necessary_right";
  CREATE TABLE "position_necessary_right"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "role_id" uuid NOT NULL  	,	
   
    "position_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "position_right_parameter";
  CREATE TABLE "position_right_parameter"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "role_id" uuid NOT NULL  	,	
   
    "position_did" uuid NOT NULL  	,	
   
    "right_parameter_did" uuid NOT NULL  	,	
   
    "parameter_value" TEXT DEFAULT NULL  	,	
   
    "valid_from" DATE DEFAULT NULL  	,	
   
    "valid_to" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "postalcode";
  CREATE TABLE "postalcode"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "province" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "procurement";
  CREATE TABLE "procurement"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "invoice_in_item_id" uuid NOT NULL  	,	
   
    "purchase_price_netto" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid NOT NULL  	,	
   
    "sales_price_netto" DECIMAL NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "stock_quantity" DECIMAL NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "product";
  CREATE TABLE "product"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "manufacturer" VARCHAR DEFAULT NULL  	,	
   
    "article_number" VARCHAR NOT NULL  	,	
   
    "code" VARCHAR DEFAULT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "category_did" uuid NOT NULL  	,	
   
    "category_by_text" VARCHAR DEFAULT NULL  	,	
   
    "partner_id" uuid DEFAULT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "product_supplier_url" VARCHAR DEFAULT NULL  	,	
   
    "min_stock_quantity" DECIMAL DEFAULT NULL  	,	
   
    "current_price" DECIMAL DEFAULT NULL  	,	
   
    "sale_price" DECIMAL DEFAULT NULL  	,	
   
    "active_flag" boolean NOT NULL  	,	
   
    "is_erp" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "product_alt_name";
  CREATE TABLE "product_alt_name"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "language_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "product_list_price";
  CREATE TABLE "product_list_price"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "list_price_date" DATE NOT NULL  	,	
   
    "list_price_netto" DECIMAL NOT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "product_productfee";
  CREATE TABLE "product_productfee"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "package_material_id" uuid NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "project";
  CREATE TABLE "project"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "project_code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "inst_loc_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE NOT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
   
    "project_date" DATE DEFAULT NULL  	,	
   
    "project_status_did" uuid NOT NULL  	,	
   
    "settlement_basis_did" uuid DEFAULT NULL  	,	
   
    "settlement_frequency_did" uuid DEFAULT NULL  	,	
   
    "payment_deadline" SMALLINT DEFAULT NULL  	,	
   
    "technical_content" text DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "margin" DECIMAL DEFAULT NULL  	,	
   
    "hourly_rate" DECIMAL DEFAULT NULL  	,	
   
    "distance_fee" DECIMAL DEFAULT NULL  	,	
   
    "departure_fee" DECIMAL DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "rate_margin";
  CREATE TABLE "rate_margin"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "buy_margin" DECIMAL NOT NULL  	,	
   
    "sell_margin" DECIMAL NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "branch_id" uuid DEFAULT NULL  	,	
   
    "start_date" DATE NOT NULL  	,	
   
    "end_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "rcomment";
  CREATE TABLE "rcomment"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "cgroup" VARCHAR NOT NULL  	,	
   
    "cid" VARCHAR NOT NULL  	,	
   
    "commenttxt" text NOT NULL  	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "comment_datetime" timestamp NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "report_template";
  CREATE TABLE "report_template"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "report_type_did" uuid NOT NULL  	,	
   
    "template_content" TEXT NOT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "created_date" timestamp NOT NULL  	,	
   
    "created_by" uuid NOT NULL  	,	
   
    "updated_date" timestamp DEFAULT NULL  	,	
   
    "updated_by" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "representative_log";
  CREATE TABLE "representative_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "authorized_representative_id" uuid NOT NULL  	,	
   
    "log_date" timestamp NOT NULL  	,	
   
    "log_type_did" uuid NOT NULL  	,	
   
    "transaction_id" uuid DEFAULT NULL  	,	
   
    "performed_by" uuid NOT NULL  	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "details" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "role";
  CREATE TABLE "role"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "searchkey" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "role_figdef";
  CREATE TABLE "role_figdef"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "role_id" uuid NOT NULL  	,	
   
    "figdef_id" uuid NOT NULL  	,	
   
    "canview" boolean DEFAULT NULL  	,	
   
    "canedit" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "role_right";
  CREATE TABLE "role_right"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "role_id" uuid NOT NULL  	,	
   
    "elementary_right_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "ruser";
  CREATE TABLE "ruser"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "user_name" VARCHAR NOT NULL  	,	
   
    "worker_id" uuid DEFAULT NULL  	,	
   
    "partner_id" uuid DEFAULT NULL  	,	
   
    "role_id" uuid DEFAULT NULL  	,	
   
    "last_name" VARCHAR DEFAULT NULL  	,	
   
    "first_name" VARCHAR DEFAULT NULL  	,	
   
    "password_hash" VARCHAR NOT NULL  	,	
   
    "password_reset_token" VARCHAR DEFAULT NULL  	,	
   
    "password_reset_expires" timestamp DEFAULT NULL  	,	
   
    "last_password_change" timestamp DEFAULT NULL  	,	
   
    "email" VARCHAR NOT NULL  	,	
   
    "user_enabled" boolean NOT NULL  	,	
   
    "must_change_pwd" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "ruser_role";
  CREATE TABLE "ruser_role"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "role_id" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "scheduled_transfer";
  CREATE TABLE "scheduled_transfer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "source_branch_id" uuid NOT NULL  	,	
   
    "target_branch_id" uuid NOT NULL  	,	
   
    "schedule_type_did" uuid NOT NULL  	,	
   
    "day_of_week" SMALLINT DEFAULT NULL  	,	
   
    "day_of_month" SMALLINT DEFAULT NULL  	,	
   
    "transfer_time" TIME NOT NULL  	,	
   
    "security_company_id" uuid DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "created_by" uuid NOT NULL  	,	
   
    "created_date" timestamp NOT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "security_company";
  CREATE TABLE "security_company"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "contract_number" VARCHAR DEFAULT NULL  	,	
   
    "contact_name" VARCHAR DEFAULT NULL  	,	
   
    "phone" VARCHAR DEFAULT NULL  	,	
   
    "email" VARCHAR DEFAULT NULL  	,	
   
    "address" VARCHAR DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "sequencer";
  CREATE TABLE "sequencer"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "seq_current_value" DECIMAL NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "settlement";
  CREATE TABLE "settlement"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "project_id" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "sick_pay_period";
  CREATE TABLE "sick_pay_period"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "from_date" DATE NOT NULL  	,	
   
    "to_date" DATE DEFAULT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "reason_did" uuid DEFAULT NULL  	,	
   
    "description" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "site";
  CREATE TABLE "site"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "zip_code" VARCHAR NOT NULL  	,	
   
    "settlement" VARCHAR NOT NULL  	,	
   
    "street_house" VARCHAR NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "stock";
  CREATE TABLE "stock"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "warehouse_id" uuid NOT NULL  	,	
   
    "expiry_date" DATE NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "stock_movement";
  CREATE TABLE "stock_movement"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "product_id" uuid NOT NULL  	,	
   
    "warehouse_id" uuid NOT NULL  	,	
   
    "movement_date" timestamp NOT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "partner_id" uuid NOT NULL  	,	
   
    "source_warehouse_id" uuid DEFAULT NULL  	,	
   
    "destination_warehouse_id" uuid DEFAULT NULL  	,	
   
    "movement_type_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "system_parameter";
  CREATE TABLE "system_parameter"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "param_key" VARCHAR NOT NULL  	,	
   
    "param_value" VARCHAR DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "param_group" VARCHAR DEFAULT NULL  	,	
   
    "is_editable" boolean NOT NULL  	,	
   
    "last_updated" timestamp DEFAULT NULL  	,	
   
    "updated_by" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "task";
  CREATE TABLE "task"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "description" VARCHAR NOT NULL  	,	
   
    "task_rule_type_did" uuid NOT NULL  	,	
   
    "rule" text DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "transaction";
  CREATE TABLE "transaction"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_number" VARCHAR NOT NULL  	,	
   
    "branch_id" uuid NOT NULL  	,	
   
    "transaction_date" timestamp NOT NULL  	,	
   
    "transaction_type_did" uuid NOT NULL  	,	
   
    "amount" DECIMAL NOT NULL  	,	
   
    "fee_amount" DECIMAL NOT NULL  	,	
   
    "customer_type_did" uuid NOT NULL  	,	
   
    "identify_mode_did" uuid NOT NULL  	,	
   
    "suspicious_transaction_flag" boolean NOT NULL  	,	
   
    "customer_id" uuid DEFAULT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "status_did" uuid NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "transaction_item";
  CREATE TABLE "transaction_item"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "band_exchange_rate_discount_id" uuid DEFAULT NULL  	,	
   
    "amount" DECIMAL NOT NULL  	,	
   
    "applied_exchange_rate" DECIMAL NOT NULL  	,	
   
    "exchange_rate_id" uuid DEFAULT NULL  	,	
   
    "pay_out_amount" DECIMAL DEFAULT NULL  	,	
   
    "denomination_rule_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "transaction_item_banknote";
  CREATE TABLE "transaction_item_banknote"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_item_id" uuid NOT NULL  	,	
   
    "currency_id" uuid NOT NULL  	,	
   
    "currency_denomination_id" uuid NOT NULL  	,	
   
    "quantity" INT NOT NULL  	,	
   
    "is_input" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "transaction_limit_override";
  CREATE TABLE "transaction_limit_override"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "transaction_id" uuid NOT NULL  	,	
   
    "limit_setting_id" uuid NOT NULL  	,	
   
    "override_amount" DECIMAL NOT NULL  	,	
   
    "override_date" timestamp NOT NULL  	,	
   
    "override_reason_did" uuid NOT NULL  	,	
   
    "approved_by" uuid NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "transfer_approval";
  CREATE TABLE "transfer_approval"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "branch_transfer_id" uuid NOT NULL  	,	
   
    "approval_level_did" uuid NOT NULL  	,	
   
    "approved_by" uuid NOT NULL  	,	
   
    "approval_date" timestamp NOT NULL  	,	
   
    "notes" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "user_basic_right";
  CREATE TABLE "user_basic_right"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "elementary_right_id" uuid NOT NULL  	,	
   
    "creator_ruser_id" uuid NOT NULL  	,	
   
    "assigned_role_id" uuid DEFAULT NULL  	,	
   
    "valid_from_dt" timestamp DEFAULT NULL  	,	
   
    "valid_to_dt" timestamp DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "user_basic_right_parameter";
  CREATE TABLE "user_basic_right_parameter"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "user_basic_right_id" uuid NOT NULL  	,	
   
    "right_parameter_did" uuid NOT NULL  	,	
   
    "parameter_value" TEXT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "user_profil";
  CREATE TABLE "user_profil"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "setting_type_did" uuid NOT NULL  	,	
   
    "setting" TEXT DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "user_rating";
  CREATE TABLE "user_rating"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrier_id" uuid DEFAULT NULL  	,	
   
    "client_id" uuid DEFAULT NULL  	,	
   
    "rated_by_carrier_id" uuid DEFAULT NULL  	,	
   
    "rated_by_client_id" uuid DEFAULT NULL  	,	
   
    "assignment_id" uuid NOT NULL  	,	
   
    "rating_date" timestamp NOT NULL  	,	
   
    "rating_value" DECIMAL NOT NULL  	,	
   
    "rating_comment" VARCHAR DEFAULT NULL  	,	
   
    "punctuality" DECIMAL NOT NULL  	,	
   
    "communication" DECIMAL NOT NULL  	,	
   
    "reliability" DECIMAL NOT NULL  	,	
   
    "satisfaction" DECIMAL NOT NULL  	,	
   
    "is_moderated" boolean NOT NULL  	,	
   
    "moderated_by" VARCHAR DEFAULT NULL  	,	
   
    "moderation_date" timestamp DEFAULT NULL  	,	
   
    "is_active" boolean NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "user_verification_log";
  CREATE TABLE "user_verification_log"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "carrier_id" uuid DEFAULT NULL  	,	
   
    "client_id" uuid DEFAULT NULL  	,	
   
    "verification_date" timestamp NOT NULL  	,	
   
    "verification_type" VARCHAR NOT NULL  	,	
   
    "api_used" VARCHAR DEFAULT NULL  	,	
   
    "request_data" VARCHAR DEFAULT NULL  	,	
   
    "response_data" VARCHAR DEFAULT NULL  	,	
   
    "is_successful" boolean NOT NULL  	,	
   
    "error_message" VARCHAR DEFAULT NULL  	,	
   
    "verified_by" VARCHAR NOT NULL  	,	
   
    "verification_ip" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "warehouse";
  CREATE TABLE "warehouse"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "base_warehouse" boolean DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker";
  CREATE TABLE "worker"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "person_id" uuid NOT NULL  	,	
   
    "employment_type_did" uuid DEFAULT NULL  	,	
   
    "worker_status_did" uuid NOT NULL  	,	
   
    "payroll_type_did" uuid DEFAULT NULL  	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "feor_did" uuid DEFAULT NULL  	,	
   
    "position" VARCHAR DEFAULT NULL  	,	
   
    "entry_date" DATE DEFAULT NULL  	,	
   
    "leaving_date" DATE DEFAULT NULL  	,	
   
    "weekly_working_hours" SMALLINT DEFAULT NULL  	,	
   
    "other_labor_notice" VARCHAR DEFAULT NULL  	,	
   
    "method_of_termination_did" uuid DEFAULT NULL  	,	
   
    "method_of_termination_desc" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker_assignment_request";
  CREATE TABLE "worker_assignment_request"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "requested_place_of_employment" CHAR DEFAULT NULL  	,	
   
    "reason" VARCHAR DEFAULT NULL  	,	
   
    "request_datetime" timestamp DEFAULT NULL  	,	
   
    "worker_assignment_request_did" uuid NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker_bank_account";
  CREATE TABLE "worker_bank_account"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "name" VARCHAR NOT NULL  	,	
   
    "country_did" uuid NOT NULL  	,	
   
    "address" VARCHAR DEFAULT NULL  	,	
   
    "swift" VARCHAR DEFAULT NULL  	,	
   
    "huf_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "huf_iban" VARCHAR DEFAULT NULL  	,	
   
    "dev_bank_account_number" VARCHAR DEFAULT NULL  	,	
   
    "dev_iban" VARCHAR DEFAULT NULL  	,	
   
    "account_owner" VARCHAR DEFAULT NULL  	,	
   
    "currency_did" uuid DEFAULT NULL  	,	
   
    "bank_account_status_did" uuid NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker_car";
  CREATE TABLE "worker_car"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "car_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE NOT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker_life_path";
  CREATE TABLE "worker_life_path"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "valid_from_date" DATE DEFAULT NULL  	,	
   
    "valid_to_date" DATE DEFAULT NULL  	,	
   
    "description" VARCHAR NOT NULL  	,	
   
    "abroad" boolean DEFAULT NULL  	,	
   
    "health_insurance_fee_settled" boolean DEFAULT NULL  	,	
   
    "who_settled_health_insurance_fee" VARCHAR DEFAULT NULL  	,	
   
    "health_insurance_fee_debt" DECIMAL DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worker_note";
  CREATE TABLE "worker_note"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "note" TEXT NOT NULL  	,	
   
    "ruser_id" uuid NOT NULL  	,	
   
    "worker_note_status_did" uuid NOT NULL  	,	
   
    "creation_dt" timestamp NOT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "working_time_schedule";
  CREATE TABLE "working_time_schedule"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "time_use_type_did" uuid NOT NULL  	,	
   
    "working_time_schedule_status_did" uuid NOT NULL  	,	
   
    "demand_id" uuid DEFAULT NULL  	,	
   
    "position_did" uuid DEFAULT NULL  	,	
   
    "day" DATE NOT NULL  	,	
   
    "worker_assignment_request_id" uuid DEFAULT NULL  	,	
   
    "sick_pay_period_id" uuid DEFAULT NULL  	,	
   
    "calendar_id" uuid NOT NULL  	,	
   
    "from_time" TIME DEFAULT NULL  	,	
   
    "to_time" TIME DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worksheet";
  CREATE TABLE "worksheet"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "code" VARCHAR NOT NULL  	,	
   
    "company_id" uuid NOT NULL  	,	
   
    "partner_id" uuid DEFAULT NULL  	,	
   
    "inst_loc_id" uuid DEFAULT NULL  	,	
   
    "project_id" uuid DEFAULT NULL  	,	
   
    "name" VARCHAR DEFAULT NULL  	,	
   
    "description" VARCHAR DEFAULT NULL  	,	
   
    "worksheet_status_did" uuid DEFAULT NULL  	,	
   
    "worksheet_open_date" DATE NOT NULL  	,	
   
    "open_worker_id" uuid NOT NULL  	,	
   
    "worksheet_begin" timestamp NOT NULL  	,	
   
    "worksheet_end" timestamp DEFAULT NULL  	,	
   
    "occasional_flag" boolean DEFAULT NULL  	,	
   
    "worksheet_close_date" DATE DEFAULT NULL  	,	
   
    "close_worker_id" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worksheet_material";
  CREATE TABLE "worksheet_material"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "material_use_did" uuid NOT NULL  	,	
   
    "worksheet_id" uuid NOT NULL  	,	
   
    "material_id" uuid DEFAULT NULL  	,	
   
    "quantity" DECIMAL NOT NULL  	,	
   
    "unit_of_measure_did" uuid NOT NULL  	,	
   
    "material_reason_did" uuid DEFAULT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "sold_flag" boolean DEFAULT NULL  	,	
   
    "status_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );


  DROP TABLE IF EXISTS "worksheet_worker";
  CREATE TABLE "worksheet_worker"
  (
      "id" uuid DEFAULT gen_random_uuid()   	,	
   
    "worksheet_id" uuid NOT NULL  	,	
   
    "worker_id" uuid NOT NULL  	,	
   
    "work_begin" timestamp NOT NULL  	,	
   
    "work_end" timestamp NOT NULL  	,	
   
    "work_time" DECIMAL NOT NULL  	,	
   
    "completed_tasks" VARCHAR NOT NULL  	,	
   
    "note" VARCHAR DEFAULT NULL  	,	
   
    "status_did" uuid DEFAULT NULL  	,	
		
  PRIMARY KEY ("id")
  );

		
	DELETE FROM dictionary where code_type_did = 'CAR_OWNER_CATEGORY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940560-a617-7c63-9e46-aff48f2b0724', 'CAR_OWNER_CATEGORY', 'CORPORATE', 'céges');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940560-baa4-7740-94e8-bb686d7206ca', 'CAR_OWNER_CATEGORY', 'EMPLOYEES', 'dolgozóé');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940560-cc61-7e3d-9fa0-0a52623782ab', 'CAR_OWNER_CATEGORY', 'RENTED', 'bérelt');

DELETE FROM dictionary where code_type_did = 'CATEGORY_GROUP';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-b375-70d9-b93d-1c1c732bebb2', 'CATEGORY_GROUP', 'CONTACT_SUBJECT', 'Kapcsolattartás témakör');

DELETE FROM dictionary where code_type_did = 'CODE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-c38b-7691-9825-3fec7e4af5b5', 'CODE_TYPE', 'ADDRESS_TYPE', 'Cím típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-cfa9-7be5-9536-53e657b2cb17', 'CODE_TYPE', 'CAR_OWNERSHIP_CATEGORY', 'Autó tulajdoni kategória');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-d8b6-7fa0-9edb-58499fec0497', 'CODE_TYPE', 'CATEGORY_GROUP', 'Kategória csoport');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-dfde-74ab-89d5-4ca05091c2c6', 'CODE_TYPE', 'CITIZENSHIP', 'Állampolgárság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-e771-78df-b9c2-8394785dcfae', 'CODE_TYPE', 'CODE_TYPE', 'Kódcsoportok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-f009-7b0d-ae02-ffabbddf0723', 'CODE_TYPE', 'COMPANY_FORM', 'Cégforma');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-f74e-7096-8afe-b17eb2d4ca79', 'CODE_TYPE', 'CONTACT_TYPE', 'Elérhetőség típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f8-fe38-7eca-8504-d84655c33435', 'CODE_TYPE', 'CONTRACT_STATUS', 'Szerződés státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-0518-77ff-a59f-a1b15f8a1920', 'CODE_TYPE', 'COUNTRY', 'Ország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-0bd6-7499-b4ff-0fb2c1aacc81', 'CODE_TYPE', 'DAY_TYPE', 'Nap típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-1295-79b0-a78e-add23568cb5a', 'CODE_TYPE', 'DEMAND_STATUS', 'Igény státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-1d30-7d77-9e47-2dbf7fc0fb73', 'CODE_TYPE', 'DOCUMENT_STATUS', 'Dokumentum státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-25ae-7a8d-9816-9a7653c8b0ed', 'CODE_TYPE', 'EDUCATIONAL_DEGREE', 'Képzettségi fok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-2cdc-7d71-8fb7-f84b3f5f6b75', 'CODE_TYPE', 'EMPLOYMENT_TYPE', 'Foglalkoztatás típusa');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-33ed-7eae-b0d9-40216ff4f7c8', 'CODE_TYPE', 'ERROR_MESSAGE', 'Hibaüzenet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-3acd-7747-95e0-fdcac12cd05e', 'CODE_TYPE', 'FEOR', 'FEOR');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-42b1-7dd5-8112-4d4fc82900bd', 'CODE_TYPE', 'LANGUAGE', 'Nyelv');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-4a7e-75ca-87e2-f4767ac95288', 'CODE_TYPE', 'MEDICAL_EXAM_RESULT', 'Üzemorvosi vizsgálat eredménye');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-5145-7878-8ea0-ff05c7de6756', 'CODE_TYPE', 'MEDICAL_EXAM_STATUS', 'Üzemorvosi vizsgálat státusza');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-57f1-75af-b503-d97a79014bf7', 'CODE_TYPE', 'METHOD_OF_TERMINATION', 'Kilépés módja');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-5ed7-71af-9d3c-c5b6d5e8dab4', 'CODE_TYPE', 'OBLIGATION', 'Kötelezttség');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-65e2-7b10-8c54-bfeedac948c2', 'CODE_TYPE', 'PARTNER_STATUS', 'Partner státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-6ca6-7572-86dc-55d0700db5aa', 'CODE_TYPE', 'PAYROLL_TYPE', 'Bérfizetés módja');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-79bb-7fbb-8370-44cf9f2b5c17', 'CODE_TYPE', 'POSITION', 'Beosztás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-8012-7217-ad60-b95579988784', 'CODE_TYPE', 'QUALIFICATION_TYPE', 'Képzettség');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-8704-7dea-980b-282d8b14378b', 'CODE_TYPE', 'REASON', 'Táppénz kategória (ok)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-8dc0-79cd-b41e-60b057b28923', 'CODE_TYPE', 'SETTLEMENT_BASIS', 'Elszámolás alapja');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-93fb-77a8-afe5-6cb65269c849', 'CODE_TYPE', 'SETTLEMENT_FREQUENCY', 'Elszámolási periódus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-a01d-7353-8b81-c1d3a4072c42', 'CODE_TYPE', 'STATUS', 'Táppénzes időszak státusza');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-a64b-7bdb-970b-00a62680414d', 'CODE_TYPE', 'TASK_TYPE', 'Feladat típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-ac8b-75ee-ba5d-c0eaf840933c', 'CODE_TYPE', 'TIME_USE_TYPE', 'idő felhasználás típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-beef-7f13-918c-7b178a8a3693', 'CODE_TYPE', 'WORKER_NOTE_STATUS', 'Munkavállalóhoz való megjegyzés státusza');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-c527-778f-b180-ba822f6f1d25', 'CODE_TYPE', 'WORKER_STATUS', 'Munkavállaló státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-cb2b-7047-958c-539cfb54f313', 'CODE_TYPE', 'WORKING_TIME_SCHEDULE_STATUS', 'Munkaidő beosztás státusz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-d13c-74f2-b632-25607e0918fa', 'CODE_TYPE', 'CURRENCY', 'Pénznem');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-d923-7a98-8a46-bebd15feae3f', 'CODE_TYPE', 'INVOICE_STATE', 'Számla állapot');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-df4d-75f6-9fe6-607b97a5db10', 'CODE_TYPE', 'INVOICE_TYPE', 'Számla típus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-e57a-73d9-80f4-0d11864918a2', 'CODE_TYPE', 'PAYMENT_METHOD', 'Fizetési mód');

DELETE FROM dictionary where code_type_did = 'COMPANY_FORM';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-f353-7ec8-aeea-f69f3ea5680a', 'COMPANY_FORM', 'BT', 'betéti társaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-f9a8-7cb4-a90d-5a41a7ec13e2', 'COMPANY_FORM', 'KFT', 'korlátolt felelősségű társaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406f9-ffdd-7755-bc02-8819c7b7c469', 'COMPANY_FORM', 'KKT', 'közkereseti társaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-0604-7946-85c2-54c509c440ff', 'COMPANY_FORM', 'NYRT', 'nyilvánosan működő részvénytársaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-0c03-71a8-8f1f-aa50635ce729', 'COMPANY_FORM', 'SE', 'Európai társaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-120d-7dfc-9fcb-7939e4593c98', 'COMPANY_FORM', 'ZRT', 'zártkörűen működő részvénytársaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-188f-7263-bc26-de28b1c17e74', 'COMPANY_FORM', 'PERSON', 'Magánszemély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-2106-729f-8690-046fbe0429a0', 'COMPANY_FORM', 'SOLE_PROPRIETOR', 'Egyéni vállalkozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-2785-782c-a080-3ac06e954c6d', 'COMPANY_FORM', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'CONTRACT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-3812-7052-ba5a-d9d4ee68fe0e', 'CONTRACT_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-3e0c-7f2e-83da-b097c462cfd5', 'CONTRACT_STATUS', 'EXPIRED', 'Lejárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-43e4-758f-9f3c-5766cfcbc985', 'CONTRACT_STATUS', 'PLAN', 'Terv');

DELETE FROM dictionary where code_type_did = 'COUNTRY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-51d9-7871-8293-9af289183bfa', 'COUNTRY', 'ALB', 'Albánia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-57d7-7d52-a98f-35b1c681ffc2', 'COUNTRY', 'AND', 'Andorra');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-5e20-7fa2-b790-b7d3b422e966', 'COUNTRY', 'AUT', 'Ausztria');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-65dc-736a-a2a5-3970574a034b', 'COUNTRY', 'BEL', 'Belgium');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-6c8a-7db9-a4d7-6edf6a5ce819', 'COUNTRY', 'BGR', 'Bulgária');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-729b-74a5-948a-1a7974c13544', 'COUNTRY', 'BLR', 'Fehéroroszország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-7860-7d64-a5fb-68d6dc91dec0', 'COUNTRY', 'CHE', 'Svájc');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-7e26-75e8-b6e4-c2ce7f4a4cd8', 'COUNTRY', 'CZE', 'Csehország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-83d5-7795-8065-4ac0e8b2e386', 'COUNTRY', 'DEU', 'Németország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-8f86-7c7e-8a5f-259f8096eea3', 'COUNTRY', 'DNK', 'Dánia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-95fe-71b9-bad8-0b7ca8bea2bc', 'COUNTRY', 'ESP', 'Spanyolország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-a44c-76cd-8d39-3c2a13f66d66', 'COUNTRY', 'EST', 'Észtország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-aabd-71a7-99c7-b85e976b90d9', 'COUNTRY', 'FIN', 'Finnország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-b0a8-7b58-9df2-f8a0bcc61f68', 'COUNTRY', 'FRA', 'Franciaország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-b6b6-7c41-a265-a3f3cf39c857', 'COUNTRY', 'GBR', 'Egyesült Királyság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-c359-71ff-86bb-643b0a8a73b1', 'COUNTRY', 'GRC', 'Görögország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-ca78-74d8-9977-985953e6fecd', 'COUNTRY', 'HRV', 'Horvátország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-d0ab-74cf-9334-c56ea0357188', 'COUNTRY', 'HUN', 'Magyarország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-d722-7bbe-a21d-496fb9c25305', 'COUNTRY', 'IRL', 'Írország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-dde0-7bf9-bfd2-0d9f9d95b90e', 'COUNTRY', 'ISL', 'Izland');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-e789-7030-9862-ad2e27cbfea9', 'COUNTRY', 'ITA', 'Olaszország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-edf0-78ad-b4e2-75c3fc34c9a9', 'COUNTRY', 'LIE', 'Liechtenstein');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fa-f9b6-7d6e-8f3d-28f9d6b259a8', 'COUNTRY', 'LTU', 'Litvánia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-002b-7f44-967a-639f5b08cb6d', 'COUNTRY', 'LUX', 'Luxemburg');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-0939-7bd8-98e7-ccb91b73aded', 'COUNTRY', 'LVA', 'Lettország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-123c-7849-89fd-77cc19ef99c0', 'COUNTRY', 'MCO', 'Monaco');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-1cdc-745b-bc07-a4196eaee778', 'COUNTRY', 'MDA', 'Moldova');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-2648-78d9-802e-a50fec4042a9', 'COUNTRY', 'MKD', '(Észak-)Macedónia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-2d2f-7e59-9beb-ed4e396710c1', 'COUNTRY', 'MLT', 'Málta');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-5f1f-7055-8f21-dd1db6e73729', 'COUNTRY', 'MNE', 'Montenegró');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-79a5-73be-9e37-0c1a18e7abd4', 'COUNTRY', 'NLD', 'Hollandia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-8188-7c4d-95ae-c7bbd62d7d6d', 'COUNTRY', 'NOR', 'Norvégia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-8882-7989-b05d-1fa3c3839eff', 'COUNTRY', 'POL', 'Lengyelország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-8f24-7ddc-bdda-08534a645620', 'COUNTRY', 'PRT', 'Portugália');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-95e3-74f3-adb7-5b5d254cabca', 'COUNTRY', 'ROU', 'Románia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-9c02-76de-9f71-e06ffa0c8aa5', 'COUNTRY', 'RUS', 'Oroszország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-a1c6-7ee8-aebc-7751464370d7', 'COUNTRY', 'SMR', 'San Marino');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-acaf-756b-9788-dc06c9080ee0', 'COUNTRY', 'SRB', 'Szerbia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-b2ba-71a0-8a82-4fc2402f3cbf', 'COUNTRY', 'SVK', 'Szlovákia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-b84b-74bd-87f0-77b4a51dde80', 'COUNTRY', 'SVN', 'Szlovénia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-bdbe-7822-9280-00c5509ae59b', 'COUNTRY', 'SWE', 'Svédország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-c314-7967-8fda-590a3b10b6a9', 'COUNTRY', 'TUR', 'Törökország');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-c8be-7892-a7b0-c61184e26b33', 'COUNTRY', 'UKR', 'Ukrajna');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-ce3e-7c71-990e-c872e9f9b17c', 'COUNTRY', 'VAT', 'Vatikán');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-d2f0-7b8c-9a4d-5e1f3b6c3d1e', 'COUNTRY', 'USA', 'Egyesült Államok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-d7a2-7b8c-9a4d-5e1f3b6c3d1e', 'COUNTRY', 'CAN', 'Kanada');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-d8a3-7b8c-9a4d-5e1f3b6c3d1f', 'COUNTRY', 'ARG', 'Argentína');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-d9a4-7b8c-9a4d-5e1f3b6c3d20', 'COUNTRY', 'AUS', 'Ausztrália');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-daa5-7b8c-9a4d-5e1f3b6c3d21', 'COUNTRY', 'BIH', 'Bosznia-Hercegovina');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-dba6-7b8c-9a4d-5e1f3b6c3d22', 'COUNTRY', 'BRA', 'Brazília');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-dca7-7b8c-9a4d-5e1f3b6c3d23', 'COUNTRY', 'CHN', 'Kína');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-dda8-7b8c-9a4d-5e1f3b6c3d24', 'COUNTRY', 'CYP', 'Ciprus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-dea9-7b8c-9a4d-5e1f3b6c3d25', 'COUNTRY', 'EGY', 'Egyiptom');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-dfaa-7b8c-9a4d-5e1f3b6c3d26', 'COUNTRY', 'IND', 'India');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e0ab-7b8c-9a4d-5e1f3b6c3d27', 'COUNTRY', 'ISR', 'Izrael');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e1ac-7b8c-9a4d-5e1f3b6c3d28', 'COUNTRY', 'JPN', 'Japán');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e2ad-7b8c-9a4d-5e1f3b6c3d29', 'COUNTRY', 'KOR', 'Dél-Korea');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e3ae-7b8c-9a4d-5e1f3b6c3d2a', 'COUNTRY', 'MEX', 'Mexikó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e4af-7b8c-9a4d-5e1f3b6c3d2b', 'COUNTRY', 'ZAF', 'Dél-afrikai Köztársaság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e5b0-7b8c-9a4d-5e1f3b6c3d2c', 'COUNTRY', 'IDN', 'Indonézia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e6b1-7b8c-9a4d-5e1f3b6c3d2d', 'COUNTRY', 'NZL', 'Új-Zéland');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e7b2-7b8c-9a4d-5e1f3b6c3d2e', 'COUNTRY', 'THA', 'Thaiföld');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e8b3-7b8c-9a4d-5e1f3b6c3d2f', 'COUNTRY', 'SGP', 'Szingapúr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e9b4-7b8c-9a4d-5e1f3b6c3d30', 'COUNTRY', 'MYS', 'Malajzia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-eab5-7b8c-9a4d-5e1f3b6c3d31', 'COUNTRY', 'VNM', 'Vietnám');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-ebb6-7b8c-9a4d-5e1f3b6c3d32', 'COUNTRY', 'ARE', 'Egyesült Arab Emírségek');

DELETE FROM dictionary where code_type_did = 'DAY_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-e4dc-7946-bdef-3a9563e31b0b', 'DAY_TYPE', 'HOLIDAY', 'Ünnepnap');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-eb13-7408-b386-df93d83b5fb5', 'DAY_TYPE', 'SUNDAY', 'Vasárnap');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-f114-7e66-933c-cc1bfd852569', 'DAY_TYPE', 'WORK', 'Munkanap');

DELETE FROM dictionary where code_type_did = 'DEMAND_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fb-fe1a-7104-ae01-77082838086a', 'DEMAND_STATUS', 'ACTIVE', 'Élő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-048c-73e7-951b-b897d1103afb', 'DEMAND_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-0c6b-7c98-bdce-d004740b3c85', 'DEMAND_STATUS', 'DELETED', 'Törölt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-131e-7468-ba4e-dcab75954681', 'DEMAND_STATUS', 'PLAN', 'Terv');

DELETE FROM dictionary where code_type_did = 'DOCUMENT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-218e-70d5-92f6-b6435cbad1bc', 'DOCUMENT_STATUS', 'ACTIVE', 'aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-2854-7835-817c-7974de5de2ba', 'DOCUMENT_STATUS', 'ASKED', 'bekért');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-3004-724d-bcd5-f3c5b6c46e24', 'DOCUMENT_STATUS', 'EXPIRED', 'lejárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-37af-70d8-8bad-6cbd00488a2b', 'DOCUMENT_STATUS', 'REQUESTED', 'igényelt');

DELETE FROM dictionary where code_type_did = 'EDUCATION_DEGREE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-4d91-7ad9-ac9a-3d3143fae64a', 'EDUCATION_DEGREE', 'BSC', 'BSC');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-5404-7924-927c-5f2a00444a20', 'EDUCATION_DEGREE', 'GENERAL', '8 általános');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-5d0f-7830-bc76-3467f5443cca', 'EDUCATION_DEGREE', 'HIGH_SCHOOL', 'gimnáziumi érettségi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-6754-7b3a-ae66-8c7a0439b933', 'EDUCATION_DEGREE', 'MSC', 'MSC');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-6e62-7427-8111-6f05c012b1f9', 'EDUCATION_DEGREE', 'SEC_SCHOOL', 'szakközépiskolai érettségi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-7762-7fa1-916b-e6bb97808c73', 'EDUCATION_DEGREE', 'VOC_TRAINING', 'szakmunkásképző');

DELETE FROM dictionary where code_type_did = 'EMPLOYMENT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-ef89-733e-b64a-6c6254d42d43', 'EMPLOYMENT_TYPE', 'FULLTIME', 'teljes munkaidős alkalmazott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-f635-7739-a171-5cfe15063d58', 'EMPLOYMENT_TYPE', 'PARTTIME', 'részmunkaidős alkalmazott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fc-fc97-7302-ae3a-61bfeacffb0b', 'EMPLOYMENT_TYPE', 'RENDTED', 'bérelt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-fb8e-7b4b-8b4b-0f3b1f7b1b8c', 'EMPLOYMENT_TYPE', 'EXTERNAL', 'Külsős');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-01c0-7da3-9183-4ca78d6d1cdf', 'EMPLOYMENT_TYPE', 'RETIRED', 'Nyugdíjas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-0a3b-7b4e-9b4b-0f3b1f7b1b8d', 'EMPLOYMENT_TYPE', 'STUDENT', 'Diák');

DELETE FROM dictionary where code_type_did = 'ERROR_MESSAGE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-0a96-7a38-a8f2-e5d415eda6f3', 'ERROR_MESSAGE', 'CLIENT_UNIQ_001', 'Nem egyedi kliens');

DELETE FROM dictionary where code_type_did = 'FEOR';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb2ecfc6c01', 'FEOR', '11', 'Törvényhozók, igazgatási és érdek-képviseleti vezetők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb3934e446a', 'FEOR', '1', 'Fegyveres szervek felsőfokú képesítést igénylő foglalkozásai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb44a97748e', 'FEOR', '111', 'Törvényhozók, miniszterek, államtitkárok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb56213c64e', 'FEOR', '1110', 'Törvényhozó, miniszter, államtitkár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb6bd1a3212', 'FEOR', '112', 'Országos és területi közigazgatás, igazságszolgáltatás vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb7b3666641', 'FEOR', '1121', 'Országos és területi közigazgatás, igazságszolgáltatás vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb8be249c2c', 'FEOR', '1122', 'Helyi önkormányzat választott vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdb92db88048', 'FEOR', '1123', 'Helyi önkormányzat kinevezett vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdba5a498981', 'FEOR', '113', 'Országos és területi társadalmi (érdek-képviseleti), és egyéb szervezetek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdbb603cfeaa', 'FEOR', '1131', 'Társadalmi (érdek-képviseleti) és egyéb szervezet vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdbcb4c199fa', 'FEOR', '1132', 'Egyházi vezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdbdf57996be', 'FEOR', '12', 'Gazdasági, költségvetési szervezetek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdbe185aa3e3', 'FEOR', '1210', 'Gazdasági, költségvetési szervezet vezetője (igazgató, elnök, ügyvezető igazgató)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdbfdbd93c35', 'FEOR', '13', 'Termelési és szolgáltatást nyújtó egységek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc0ec3f9816', 'FEOR', '131', 'Termelési egységek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc1f6fc6188', 'FEOR', '1311', 'Mezőgazdasági, erdészeti, halászati és vadászati tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc292fb6f89', 'FEOR', '1312', 'Ipari tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc383adb3fe', 'FEOR', '1313', 'Építőipari tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc4edabd3d2', 'FEOR', '132', 'Szolgáltatást nyújtó egységek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc5f5683990', 'FEOR', '1321', 'Szállítási, logisztikai és raktározási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc67c0d6c5c', 'FEOR', '1322', 'Informatikai és telekommunikációs tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc72950fe5b', 'FEOR', '1323', 'Pénzintézeti tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc889fe490c', 'FEOR', '1324', 'Szociális tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdc9a3f9149f', 'FEOR', '1325', 'Gyermekgondozási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdca6eedf4f5', 'FEOR', '1326', 'Idősgondozási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdcb38ea6ce0', 'FEOR', '1327', 'Egészségügyi tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdcc516a698c', 'FEOR', '1328', 'Oktatási-nevelési tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdcd8638c701', 'FEOR', '1329', 'Egyéb szolgáltatást nyújtó egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdce19ce662f', 'FEOR', '133', 'Kereskedelmi, vendéglátó és hasonló szolgáltatási tevékenységet folytató egységek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdcfd4bca784', 'FEOR', '1331', 'Szálláshely-szolgáltatási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd0c92ca6b9', 'FEOR', '1332', 'Vendéglátó tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd1f600415c', 'FEOR', '1333', 'Kereskedelmi tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd2f98a9395', 'FEOR', '1334', 'Üzleti szolgáltatási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd3c138d219', 'FEOR', '1335', 'Kulturális tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd47cf0826f', 'FEOR', '1336', 'Sport- és rekreációs tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd5f5d32a4a', 'FEOR', '1339', 'Egyéb kereskedelmi, vendéglátó és hasonló szolgáltatási tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd643c5645b', 'FEOR', '14', 'Gazdasági tevékenységet segítő egységek vezetői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd7b642d792', 'FEOR', '1411', 'Számviteli és pénzügyi tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd8d861d50a', 'FEOR', '1412', 'Személyzeti vezető, humánpolitikai egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdd973f71919', 'FEOR', '1413', 'Kutatási és fejlesztési tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bddaba73040b', 'FEOR', '1414', 'Vállalati stratégiatervezési egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bddb260d39a6', 'FEOR', '1415', 'Értékesítési és marketingtevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bddc2de75eac', 'FEOR', '1416', 'Reklám-, PR- és egyéb kommunikációs tevékenységet folytató egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bddd106cfc1c', 'FEOR', '1419', 'Egyéb gazdasági tevékenységet segítő egység vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdde47c13a11', 'FEOR', '2', 'Fegyveres szervek középfokú képesítést igénylő foglalkozásai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bddfabb58f9d', 'FEOR', '21', 'Műszaki, informatikai és természettudományi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde0b7cbc892', 'FEOR', '211', 'Ipari, építőipari mérnökök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde11804a9ad', 'FEOR', '2111', 'Bányamérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde247711490', 'FEOR', '2112', 'Kohó- és anyagmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde3e0176dbf', 'FEOR', '2113', 'Élelmiszer-ipari mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde4c27a30f2', 'FEOR', '2114', 'Fa- és könnyűipari mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde5f409fa52', 'FEOR', '2115', 'Építészmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde6a02d57ba', 'FEOR', '2116', 'Építőmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde762ceaede', 'FEOR', '2117', 'Vegyészmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde8ccc3cd8c', 'FEOR', '2118', 'Gépészmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bde95fa09494', 'FEOR', '212', 'Elektromérnökök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdea29ed1607', 'FEOR', '2121', 'Villamosmérnök (energetikai mérnök)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdeb7ff4a17a', 'FEOR', '2122', 'Villamosmérnök (elektronikai mérnök)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdec042ffb3c', 'FEOR', '2123', 'Telekommunikációs mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bded9dbaa883', 'FEOR', '213', 'Egyéb mérnökök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdee7c9c6ebe', 'FEOR', '2131', 'Mezőgazdasági mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdef9fde51c1', 'FEOR', '2132', 'Erdő- és természetvédelmi mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdf06e4ccbe2', 'FEOR', '2133', 'Táj- és kertépítészmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdf1e6d9e63a', 'FEOR', '2134', 'Település- és közlekedéstervező mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6d-71be-9c3e-bdf243a749aa', 'FEOR', '2135', 'Földmérő és térinformatikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d3e6c18fe09', 'FEOR', '2136', 'Grafikus és multimédia-tervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d3f295453da', 'FEOR', '2137', 'Minőségbiztosítási mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4091003da9', 'FEOR', '2139', 'Egyéb, máshova nem sorolható mérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d41dd600d19', 'FEOR', '214', 'Szoftver- és alkalmazásfejlesztők, -elemzők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d42f7b8ca7c', 'FEOR', '2141', 'Rendszerelemző (informatikai)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d437929122c', 'FEOR', '2142', 'Szoftverfejlesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d44ea6a2efc', 'FEOR', '2143', 'Hálózat- és multimédia-fejlesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d459bba07a3', 'FEOR', '2144', 'Alkalmazásprogramozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d460fad204b', 'FEOR', '2149', 'Egyéb szoftver- és alkalmazásfejlesztő, -elemző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d47908f8d9f', 'FEOR', '215', 'Adatbázis- és hálózati elemzők, üzemeltetők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4845cd9108', 'FEOR', '2151', 'Adatbázis-tervező és -üzemeltető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d49bc626f7b', 'FEOR', '2152', 'Rendszergazda');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4ac2eb1136', 'FEOR', '2153', 'Számítógép-hálózati elemző, üzemeltető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4bdf972e40', 'FEOR', '2159', 'Egyéb adatbázis- és hálózati elemző, üzemeltető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4c50f82baf', 'FEOR', '216', 'Természettudományi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4d94f48474', 'FEOR', '2161', 'Fizikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4eedfdec09', 'FEOR', '2162', 'Csillagász');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d4fa9339a93', 'FEOR', '2163', 'Meteorológus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5012fddfa9', 'FEOR', '2164', 'Kémikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d512a0d8811', 'FEOR', '2165', 'Geológus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d529ba50dc9', 'FEOR', '2166', 'Matematikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d537990da64', 'FEOR', '2167', 'Biológus, botanikus, zoológus és rokon foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d548d25ae77', 'FEOR', '2168', 'Környezetfelmérő, -tanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5548aab949', 'FEOR', '2169', 'Egyéb természettudományi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d562ff8634f', 'FEOR', '22', 'Egészségügyi foglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d57a3a9b649', 'FEOR', '221', 'Orvosi, gyógyszerészi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d58523e3161', 'FEOR', '2211', 'Általános orvos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d595ad653ca', 'FEOR', '2212', 'Szakorvos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5ac109fec2', 'FEOR', '2213', 'Fogorvos, fogszakorvos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5b7129c05c', 'FEOR', '2214', 'Gyógyszerész, szakgyógyszerész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5ce111df0e', 'FEOR', '222', 'Humán-egészségügyi (társ)foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5decc59830', 'FEOR', '2221', 'Környezet- és foglalkozás-egészségügyi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5e6afc1758', 'FEOR', '2222', 'Optometrista');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d5fcdf64093', 'FEOR', '2223', 'Dietetikus és táplálkozási tanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d60cbded15a', 'FEOR', '2224', 'Gyógytornász');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6157e63b19', 'FEOR', '2225', 'Védőnő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d62eb393617', 'FEOR', '2226', 'Mentőtiszt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d632375d544', 'FEOR', '2227', 'Hallás- és beszédterapeuta');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d64a64eec8a', 'FEOR', '2228', 'Alternatív gyógymódot alkalmazó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d65c8e4aa0a', 'FEOR', '2229', 'Egyéb humán-egészségügyi (társ)foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d664f4785f2', 'FEOR', '223', 'Ápoló, szülész(nő) (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d676fdc7daa', 'FEOR', '2231', 'Ápoló (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d687990847c', 'FEOR', '2232', 'Szülész(nő) (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d69e9427e30', 'FEOR', '224', 'Állat- és növény-egészségügyi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6a1ee89738', 'FEOR', '2241', 'Állatorvos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6b16f51d93', 'FEOR', '2242', 'Növényorvos (növényvédelmi szakértő)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6cd87e8296', 'FEOR', '23', 'Szociális szolgáltatási foglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6d23c19616', 'FEOR', '231', 'zociális szolgáltatási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6e86de804b', 'FEOR', '2311', 'Szociálpolitikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d6f69681b92', 'FEOR', '2312', 'Szociális munkás és tanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d70382b58ee', 'FEOR', '24', 'Oktatók, pedagógusok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d713a9988b9', 'FEOR', '241', 'Felsőoktatási intézményi oktatók, tanárok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d725abbccb3', 'FEOR', '2410', 'Egyetemi, főiskolai oktató, tanár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7399cf35cf', 'FEOR', '242', 'özépfokú nevelési-oktatási intézményi oktatók, tanárok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7497b3d4fe', 'FEOR', '2421', 'Középiskolai tanár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d759135c981', 'FEOR', '2422', 'Középfokú nevelési-oktatási intézményi szakoktató, gyakorlati oktató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d76d36d3d4a', 'FEOR', '243', 'Óvodai és alapfokú nevelési-oktatási intézményi tanárok, oktatók, nevelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d77107607db', 'FEOR', '2431', 'Általános iskolai tanár, tanító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7825e9f36c', 'FEOR', '2432', 'Csecsemő- és kisgyermeknevelő, óvodapedagógus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d79c0bda7a6', 'FEOR', '244', 'Speciális oktatók, nevelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7a3d10c545', 'FEOR', '2441', 'Gyógypedagógus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7be98bc359', 'FEOR', '2442', 'Konduktor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7cd9e59fa7', 'FEOR', '249', 'gyéb szakképzett oktatók, nevelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7d1e02579a', 'FEOR', '2491', 'Pedagógiai szakértő, szaktanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7e5c8c00e9', 'FEOR', '2492', 'Nyelvtanár (iskolarendszeren kívül)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d7f494aacf4', 'FEOR', '2493', 'Zenetanár (iskolarendszeren kívül)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d802fd74c43', 'FEOR', '2494', 'Egyéb művészetek tanára (iskolarendszeren kívül)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d81804a3bee', 'FEOR', '2495', 'Informatikatanár (iskolarendszeren kívül)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d828a97fb0b', 'FEOR', '2499', 'Egyéb szakképzett oktató, nevelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d837589d230', 'FEOR', '25', 'Gazdálkodási jellegű foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d84f3863dc7', 'FEOR', '251', 'Pénzügyi és számviteli foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d85e8758379', 'FEOR', '2511', 'Pénzügyi elemző és befektetési tanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d86359ef035', 'FEOR', '2512', 'Adótanácsadó, adószakértő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8751010f30', 'FEOR', '2513', 'Könyvvizsgáló, könyvelő, könyvszakértő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8827d029a8', 'FEOR', '2514', 'Kontroller');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d890bf2ec17', 'FEOR', '252', 'Szervezetirányítási, üzletpolitikai foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8ac1d377f1', 'FEOR', '2521', 'Szervezetirányítási elemző, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8bc3f8430e', 'FEOR', '2522', 'Üzletpolitikai elemző, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8cd8b21ed9', 'FEOR', '2523', 'Személyzeti és pályaválasztási szakértő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8d2b1bafde', 'FEOR', '2524', 'Képzési és személyzetfejlesztési szakértő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8ea28cedc0', 'FEOR', '253', 'Kereskedelmi és marketingfoglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d8f8afc52e1', 'FEOR', '2531', 'Piackutató, reklám- és marketingtevékenységet tervező, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d908b491a62', 'FEOR', '2532', 'PR-tevékenységet tervező, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9141612eb9', 'FEOR', '2533', 'Kereskedelmi tervező, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d928ab11da1', 'FEOR', '2534', 'Informatikai és telekommunikációs technológiai termékek értékesítéséttervező, szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d93e4e99e83', 'FEOR', '26', 'Jogi és társadalomtudományi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d944acf8b3c', 'FEOR', '261', 'Jogi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d95379d7c46', 'FEOR', '2611', 'Jogász, jogtanácsos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d96e5779d1f', 'FEOR', '2612', 'Ügyész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d97d2d723d3', 'FEOR', '2613', 'Bíró');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d98fa0ad127', 'FEOR', '2614', 'Közjegyző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d99f2a2eff8', 'FEOR', '2615', 'Ügyvéd');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9a3b4ab7cb', 'FEOR', '2619', 'Egyéb jogi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9b0882ee9c', 'FEOR', '262', 'Társadalomtudományi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9c8ff0e1f8', 'FEOR', '2621', 'Filozófus, politológus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9d8b2d0000', 'FEOR', '2622', 'Történész, régész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9e231096b2', 'FEOR', '2623', 'Néprajzkutató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3d9f2afbbc67', 'FEOR', '2624', 'Elemző közgazdász');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da0c9a45e51', 'FEOR', '2625', 'Statisztikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da1fb1803b6', 'FEOR', '2626', 'Szociológus, demográfus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da29bf3f6c3', 'FEOR', '2627', 'Nyelvész, fordító, tolmács');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da35c734ebe', 'FEOR', '2628', 'Pszichológus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da406d64b44', 'FEOR', '2629', 'Egyéb társadalomtudományi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da5cacda17a', 'FEOR', '27', 'Kulturális, sport-, művészeti és vallási foglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da65e334de2', 'FEOR', '271', 'Kulturális és sportfoglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da74f0be474', 'FEOR', '2711', 'Könyvtáros, informatikus könyvtáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da8b9a7f81f', 'FEOR', '2712', 'Levéltáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3da9221ed163', 'FEOR', '2713', 'Muzeológus, múzeumi gyűjteménygondnok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3daa05b01cbb', 'FEOR', '2714', 'Kulturális szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dab26a5ca49', 'FEOR', '2715', 'Könyv- és lapkiadó szerkesztője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dacbd2a3a11', 'FEOR', '2716', 'Újságíró, rádióműsor-, televízióműsor-szerkesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dadef34dafe', 'FEOR', '2717', 'Szakképzett edző, sportszervező, -irányító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dae9f5b0e7e', 'FEOR', '2719', 'Egyéb kulturális és sportfoglalkozású (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3daf4bb35b9f', 'FEOR', '272', 'lkotó- és előadó-művészi foglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db09a1558ea', 'FEOR', '2721', 'Író (újságíró nélkül)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db1df80cc94', 'FEOR', '2722', 'Képzőművész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db262387e53', 'FEOR', '2723', 'Iparművész, gyártmány- és ruhatervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db3aae8fbbb', 'FEOR', '2724', 'Zeneszerző, zenész, énekes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db47b420509', 'FEOR', '2725', 'Rendező, operatőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db59c55ec81', 'FEOR', '2726', 'Színész, bábművész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db6ded61063', 'FEOR', '2727', 'Táncművész, koreográfus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db74d9ce348', 'FEOR', '2728', 'Cirkuszi- és hasonló előadóművész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db878a82588', 'FEOR', '2729', 'Egyéb alkotó- és előadó-művészi foglalkozású (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3db923b0a67f', 'FEOR', '273', 'Vallási foglalkozások (felsőfokú képzettséghez kapcsolódó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbab6bc0cc9', 'FEOR', '2730', 'Pap (lelkész), egyházi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbbde188406', 'FEOR', '29', 'Egyéb magasan képzett ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbce63392bc', 'FEOR', '291', 'gyéb magasan képzett ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbda906f7c9', 'FEOR', '2910', 'Egyéb magasan képzett ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbe24bd814e', 'FEOR', '3', 'Fegyveres szervek középfokú képesítést nem igénylő foglalkozásai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dbf4264916b', 'FEOR', '31', 'Technikusok és hasonló műszaki foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc05c600465', 'FEOR', '311', 'Ipari, építőipari technikusok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc1ce189fb5', 'FEOR', '3111', 'Bányászati technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc2ed2215eb', 'FEOR', '3112', 'Kohó- és anyagtechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc357766e2c', 'FEOR', '3113', 'Élelmiszer-ipari technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc41827ba7d', 'FEOR', '3114', 'Fa- és könnyűipari technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc58328e211', 'FEOR', '3115', 'Vegyésztechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc6fd07a3eb', 'FEOR', '3116', 'Gépésztechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc7bee46df7', 'FEOR', '3117', 'Építő- és építésztechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc89e772dbc', 'FEOR', '312', 'Elektrotechnikusok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dc93eed36f7', 'FEOR', '3121', 'Villamosipari technikus (energetikai technikus)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dca26fbd33c', 'FEOR', '3122', 'Villamosipari technikus (elektronikai technikus)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dcb88227352', 'FEOR', '313', 'Egyéb technikusok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dccaf3e93b3', 'FEOR', '3131', 'Mezőgazdasági technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dcd5d599c14', 'FEOR', '3132', 'Erdő- és természetvédelmi technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dce74359fa4', 'FEOR', '3133', 'Földmérő és térinformatikai technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dcf21794cc2', 'FEOR', '3134', 'Környezetvédelmi technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dd0f312233f', 'FEOR', '3135', 'Minőségbiztosítási technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dd12148cf0b', 'FEOR', '3136', 'Műszaki rajzoló, szerkesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dd224a4d33c', 'FEOR', '3139', 'Egyéb, máshova nem sorolható technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6e-7699-a42b-3dd30cb9c380', 'FEOR', '314', 'Számítástechnikai (informatikai) és kommunikációs foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa26c4773c1e', 'FEOR', '3141', 'Informatikai és kommunikációs rendszereket kezelő technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2713715bef', 'FEOR', '3142', 'Informatikai és kommunikációs rendszerek felhasználóit támogató technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2852e7f321', 'FEOR', '3143', 'Számítógéphálózat- és rendszertechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa29858a2efd', 'FEOR', '3144', 'Webrendszer- (hálózati) technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2abf79a9cc', 'FEOR', '3145', 'Műsorszóró és audiovizuális technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2b9fea9167', 'FEOR', '3146', 'Telekommunikációs technikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2ced452a30', 'FEOR', '315', 'Folyamatirányítók (berendezések vezérlői)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2dadcb16e4', 'FEOR', '3151', 'Energetikai (erőművi) berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2e4e94c2b0', 'FEOR', '3152', 'Égető-, víz- és csatornaművi berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa2f32ed4dc3', 'FEOR', '3153', 'Vegyipari alapanyag-feldolgozó berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa304e3bb67b', 'FEOR', '3154', 'Kőolaj- és földgázfinomító berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3170226d62', 'FEOR', '3155', 'Fémgyártási berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa324868c486', 'FEOR', '3159', 'Egyéb folyamatirányító berendezés vezérlője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa334d985e5a', 'FEOR', '316', 'Üzemfenntartási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa34dfe62c36', 'FEOR', '3161', 'Munka- és termelésszervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3506852e3c', 'FEOR', '3162', 'Energetikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa36d15ccff2', 'FEOR', '3163', 'Munkavédelmi és üzembiztonsági foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa379f97f8e7', 'FEOR', '317', 'Vízi- és légijármű-vezetők, légiirányítók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa380dd5ddac', 'FEOR', '3171', 'Tengeri és belvízi hajóparancsnok, fedélzeti tiszt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa39707f8800', 'FEOR', '3172', 'Légijármű-vezető, hajózómérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3a2009063a', 'FEOR', '3173', 'Légiforgalmi irányító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3b88f54e0f', 'FEOR', '3174', 'Légiforgalmi irányítástechnikai berendezések üzemeltetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3c6627c212', 'FEOR', '319', 'gyéb műszaki foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3d0f6a2135', 'FEOR', '3190', 'Egyéb műszaki foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3e57d35490', 'FEOR', '32', 'Szakmai irányítók, felügyelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa3fe318ea00', 'FEOR', '321', 'Ipari, építőipari szakmai irányítók, felügyelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4076693020', 'FEOR', '3211', 'Bányászati szakmai irányító, felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa41db6151f9', 'FEOR', '3212', 'Feldolgozóipari szakmai irányító, felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa42f6d4cf2e', 'FEOR', '3213', 'Építőipari szakmai irányító, felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa430e7526b8', 'FEOR', '322', 'Egyéb szakmai irányítók, felügyelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa443f472a24', 'FEOR', '3221', 'Irodai szakmai irányító, felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa45e09a91f1', 'FEOR', '3222', 'Konyhafőnök, séf');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4652fd9fa1', 'FEOR', '33', 'Egészségügyi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4724046317', 'FEOR', '331', 'Ápolási és szülészeti kapcsolódó foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa488ac7c49b', 'FEOR', '3311', 'Ápoló, szakápoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4920b035e1', 'FEOR', '3312', 'Szülész(nő)i tevékenység segítője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4a6d2ba4da', 'FEOR', '332', 'Egészségügyi asszisztensek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4b004498cc', 'FEOR', '3321', 'Általános egészségügyi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4c0ce7362a', 'FEOR', '3322', 'Egészségügyi dokumentátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4d7969155f', 'FEOR', '3323', 'Orvosi képalkotó diagnosztikai és terápiás berendezések kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4ed60d4eec', 'FEOR', '3324', 'Orvosi laboratóriumi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa4f57b4c7c9', 'FEOR', '3325', 'Fogászati asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5052ad19d6', 'FEOR', '3326', 'Gyógyszertári és gyógyszerellátási asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa510f1e170c', 'FEOR', '3327', 'Alternatív gyógymódok alkalmazásának segítője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa52d1adaecb', 'FEOR', '333', 'umánegészségügyhöz kapcsolódó foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5325cdcc6e', 'FEOR', '3331', 'Környezet- és foglalkozás-egészségügyi kiegészítő foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa54de11f0ad', 'FEOR', '3332', 'Fizioterápiás asszisztens, masszőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5528608ede', 'FEOR', '3333', 'Fogtechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa56bdef1979', 'FEOR', '3334', 'Ortopédiai eszközkészítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5750cb0181', 'FEOR', '3335', 'Látszerész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5886a92d94', 'FEOR', '3339', 'Egyéb, humánegészségügyhöz kapcsolódó foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa598eac151d', 'FEOR', '334', 'Állat- és növényegészségügyhöz kapcsolódó foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5ad377c8e5', 'FEOR', '3341', 'Állatorvosi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5b5631e3ab', 'FEOR', '3342', 'Növényorvosi (növényvédelmi) asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5cf25b4236', 'FEOR', '34', 'Oktatási asszisztensek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5ddb67a373', 'FEOR', '341', 'Oktatási asszisztensek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5ee247cfb8', 'FEOR', '3410', 'Oktatási asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa5f69e7c505', 'FEOR', '35', 'Szociális gondozási és munkaerő-piaci szolgáltatási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa60caf8b116', 'FEOR', '351', 'Szociális foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa618307c9a3', 'FEOR', '3511', 'Szociális segítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa62e6cd71a0', 'FEOR', '3512', 'Hivatásos nevelőszülő, főállású anya');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6310a83835', 'FEOR', '3513', 'Szociális gondozó, szakgondozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa646634abd8', 'FEOR', '3514', 'Jelnyelvi tolmács');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa658ce9efdd', 'FEOR', '3515', 'Ifjúságsegítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa66578e8aac', 'FEOR', '352', 'Munkaerő-piaci szolgáltatási ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa67f03a7b03', 'FEOR', '3520', 'Munkaerő-piaci szolgáltatási ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6827cd25df', 'FEOR', '36', 'Üzleti jellegű szolgáltatások ügyintézői, hatósági ügyintézők, ügynökök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa695446856b', 'FEOR', '361', 'Pénzügyi, gazdasági ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6af3cde5b7', 'FEOR', '3611', 'Pénzügyi ügyintéző (a pénzintézeti ügyintéző kivételével)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6bd618d3ec', 'FEOR', '3612', 'Pénzintézeti ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6cd560b814', 'FEOR', '3613', 'Tőzsde- és pénzügyi ügynök, bróker');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6dde906ac7', 'FEOR', '3614', 'Számviteli ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6eebf18761', 'FEOR', '3615', 'Statisztikai ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa6fe646458f', 'FEOR', '3616', 'Értékbecslő, kárbecslő, kárszakértő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa70653a7c84', 'FEOR', '362', 'ereskedelmi és értékesítési ügyintézők, ügynökök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa718a78a9a7', 'FEOR', '3621', 'Biztosítási ügynök, ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa723524db3c', 'FEOR', '3622', 'Kereskedelmi ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa73f90cebdf', 'FEOR', '3623', 'Anyaggazdálkodó, felvásárló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa74d63b1d81', 'FEOR', '3624', 'Ügynök (a biztosítási ügynök kivételével)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa75c2208e8a', 'FEOR', '363', 'gyéb üzleti jellegű szolgáltatások ügyintézői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7697d2b81b', 'FEOR', '3631', 'Konferencia- és rendezvényszervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa777dbf4f44', 'FEOR', '3632', 'Marketing- és PR-ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa78e5b15931', 'FEOR', '3633', 'Ingatlanügynök, ingatlanforgalmazási ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa79d9a85cb7', 'FEOR', '3639', 'Egyéb, máshova nem sorolható üzleti jellegű szolgáltatás ügyintézője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7aaaf503b8', 'FEOR', '364', 'Igazgatási és jogi asszisztensek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7b9cf6536d', 'FEOR', '3641', 'Személyi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7c2e91b041', 'FEOR', '3642', 'Jogi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7d9afee00e', 'FEOR', '3649', 'Egyéb igazgatási és jogi asszisztens');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7e65261759', 'FEOR', '365', 'Hatósági ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa7ff90909f9', 'FEOR', '3651', 'Vám- és pénzügyőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa80d95a8d34', 'FEOR', '3652', 'Adó- és illetékhivatali ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8195fcbd21', 'FEOR', '3653', 'Társadalombiztosítási és segélyezési hatósági ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa82c070f0ce', 'FEOR', '3654', 'Hatósági engedélyek kiadásával foglalkozó ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa83d8cfb63b', 'FEOR', '3655', 'Nyomozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8416566555', 'FEOR', '3656', 'Végrehajtó, adósságbehajtó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa858a546052', 'FEOR', '3659', 'Egyéb hatósági ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8602810a22', 'FEOR', '37', 'Művészeti, kulturális, sport- és vallási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa875a957ba3', 'FEOR', '371', 'Művészeti és kulturális foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8892e5c626', 'FEOR', '3711', 'Segédszínész, statiszta');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa89d551814b', 'FEOR', '3712', 'Segédrendező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8a9af6af13', 'FEOR', '3713', 'Fényképész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8b604e11c5', 'FEOR', '3714', 'Díszletező, díszítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8c06cb9f78', 'FEOR', '3715', 'Kiegészítő filmgyártási és színházi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8d0f8829bb', 'FEOR', '3716', 'Lakberendező, dekoratőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8e043c8abb', 'FEOR', '3717', 'Kulturális intézményi szaktechnikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa8f40a295d5', 'FEOR', '3719', 'Egyéb művészeti és kulturális foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa90cf8b7679', 'FEOR', '372', 'Sport- és szabadidős foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa9124064672', 'FEOR', '3721', 'Sportoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa928899103e', 'FEOR', '3722', 'Fitnesz- és rekreációs program irányítója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa93b0f7d505', 'FEOR', '373', 'Egyéb vallási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da6f-7be2-ac42-aa942233af0e', 'FEOR', '3730', 'Egyéb vallási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11074199974e', 'FEOR', '39', 'Egyéb ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11080a66e7b9', 'FEOR', '391', 'Egyéb ügyintézők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1109a036c381', 'FEOR', '3910', 'Egyéb ügyintéző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110a7d8a77cb', 'FEOR', '4', 'IRODAI ÉS ÜGYVITELI (ÜGYFÉLKAPCSOLATI) FOGLALKOZÁSOK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110ba2d0a6c4', 'FEOR', '41', 'Irodai, ügyviteli foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110c105b85f6', 'FEOR', '411', 'Általános irodai, ügyviteli foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110ded434a5c', 'FEOR', '4111', 'Titkár(nő)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110e09d1b3f0', 'FEOR', '4112', 'Általános irodai adminisztrátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-110fd37b8513', 'FEOR', '4113', 'Gépíró, szövegszerkesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111059d8b097', 'FEOR', '4114', 'Adatrögzítő, kódoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11112c37d434', 'FEOR', '412', 'Számviteli foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11120aeda233', 'FEOR', '4121', 'Könyvelő (analitikus)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11136fecc479', 'FEOR', '4122', 'Bérelszámoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1114ebefa330', 'FEOR', '4123', 'Pénzügyi, statisztikai, biztosítási adminisztrátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1115f508224e', 'FEOR', '4129', 'Egyéb számviteli foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1116a6bacea2', 'FEOR', '413', 'rodai szaknyilvántartási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1117ab4e8b18', 'FEOR', '4131', 'Készlet- és anyagnyilvántartó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1118db3630e3', 'FEOR', '4132', 'Szállítási, szállítmányozási nyilvántartó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11190faeeca4', 'FEOR', '4133', 'Könyvtári, levéltári nyilvántartó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111a46e6f129', 'FEOR', '4134', 'Humánpolitikai adminisztrátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111bd74861d3', 'FEOR', '4135', 'Postai szolgáltató (kézbesítő, válogató)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111c14d99932', 'FEOR', '4136', 'Iratkezelő, irattáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111dc6179a47', 'FEOR', '419', 'Egyéb irodai, ügyviteli foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111ed1c99b01', 'FEOR', '4190', 'Egyéb, máshova nem sorolható irodai, ügyviteli foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-111f1e80a61f', 'FEOR', '42', 'Ügyfélkapcsolati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-112046ded590', 'FEOR', '421', 'Pénzkezelők, pénzintézeti pénztárosok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-11219a826fbb', 'FEOR', '4211', 'Banki pénztáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1122e7ff7d92', 'FEOR', '4212', 'Szerencsejáték-szervező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-112337241cdc', 'FEOR', '4213', 'Zálogházi ügyintéző és pénzkölcsönző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da70-7064-a23c-1124455fcf12', 'FEOR', '422', 'Ügyfélkapcsolati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1213700a3551', 'FEOR', '4221', 'Utazásszervező, tanácsadó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1214de8eb44c', 'FEOR', '4222', 'Recepciós');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1215d96a8d3f', 'FEOR', '4223', 'Szállodai recepciós');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12165974deb7', 'FEOR', '4224', 'Ügyfél- (vevő)tájékoztató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121713c41d2e', 'FEOR', '4225', 'Ügyfélszolgálati központ tájékoztatója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12184d15b4e2', 'FEOR', '4226', 'Lakossági kérdező, összeíró');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1219886414b4', 'FEOR', '4227', 'Postai ügyfélkapcsolati foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121a0d4cccac', 'FEOR', '4229', 'Egyéb ügyfélkapcsolati foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121b14d66c5c', 'FEOR', '5', 'KERESKEDELMI ÉS SZOLGÁLTATÁSI FOGLALKOZÁSOK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121c9b71c7fe', 'FEOR', '51', 'Kereskedelmi és vendéglátó-ipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121daecada49', 'FEOR', '511', 'Kereskedelmi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121e89983458', 'FEOR', '5111', 'Kereskedő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-121f8043a00b', 'FEOR', '5112', 'Vezető eladó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1220bc0a508f', 'FEOR', '5113', 'Bolti eladó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12214b0d62bb', 'FEOR', '5114', 'Kölcsönző');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1222ada3c64a', 'FEOR', '5115', 'Piaci, utcai árus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1223132e79df', 'FEOR', '5116', 'Piaci, utcai étel- és italárus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1224cd36dfa5', 'FEOR', '5117', 'Bolti pénztáros, jegypénztáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1225b2f57021', 'FEOR', '512', 'Egyéb kereskedelmi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12265e750856', 'FEOR', '5121', 'Üzemanyagtöltő állomás kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12272fb89619', 'FEOR', '5122', 'Áru- és divatbemutató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122899a405f2', 'FEOR', '5123', 'Telefonos (multimédiás) értékesítési ügynök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1229b2e153f5', 'FEOR', '5129', 'Egyéb, máshova nem sorolható kereskedelmi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122a0ef23375', 'FEOR', '513', 'Vendéglátó-ipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122b02f69595', 'FEOR', '5131', 'Vendéglős');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122c265ca43b', 'FEOR', '5132', 'Pincér');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122d2d673bb1', 'FEOR', '5133', 'Pultos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122e370b1731', 'FEOR', '5134', 'Szakács');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-122fc33bc757', 'FEOR', '5135', 'Cukrász');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12300578c71f', 'FEOR', '52', 'Szolgáltatási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12316d488e5e', 'FEOR', '521', 'Személyi szolgáltatási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12321a2ce3de', 'FEOR', '5211', 'Fodrász');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1233f8870dc2', 'FEOR', '5212', 'Kozmetikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1234a84e0df5', 'FEOR', '5213', 'Manikűrös, pedikűrös');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1235835c881c', 'FEOR', '5219', 'Egyéb személyi szolgáltatási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123614a2fc1f', 'FEOR', '522', 'Személygondozási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12373bd38f24', 'FEOR', '5221', 'Gyermekfelügyelő, dajka');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1238608b8d0f', 'FEOR', '5222', 'Segédápoló, műtőssegéd');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1239350ae3e4', 'FEOR', '5223', 'Házi gondozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123a023d56fb', 'FEOR', '5229', 'Egyéb személygondozási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123bb4e897f1', 'FEOR', '523', 'Utaskísérők, jegykezelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123c135003ce', 'FEOR', '5231', 'Kalauz, menetjegyellenőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123d2399c260', 'FEOR', '5232', 'Utaskísérő (repülőn, hajón)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123ea9c092f2', 'FEOR', '5233', 'Idegenvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-123fa87fc27c', 'FEOR', '524', 'Épületfenntartási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12400db5371d', 'FEOR', '5241', 'Vezető takarító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12412b3f3bd4', 'FEOR', '5242', 'Házvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1242e773d1df', 'FEOR', '5243', 'Épületgondnok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1243fa263b21', 'FEOR', '525', 'Személy- és vagyonvédelmi foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1244364cdfa8', 'FEOR', '5251', 'Rendőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1245395e1a57', 'FEOR', '5252', 'Tűzoltó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1246f24ea490', 'FEOR', '5253', 'Büntetés-végrehajtási őr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12479effd3c1', 'FEOR', '5254', 'Vagyonőr, testőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12486bcd29a2', 'FEOR', '5255', 'Természetvédelmi őr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12497e5bd35b', 'FEOR', '5256', 'Közterület-felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124af36ac9e1', 'FEOR', '5259', 'Egyéb személy- és vagyonvédelmi foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124b61a586f0', 'FEOR', '529', 'Egyéb szolgáltatási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124c4a545b6a', 'FEOR', '5291', 'Járművezető-oktató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124d5d18aa3b', 'FEOR', '5292', 'Hobbiállat-gondozó, -kozmetikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124e83fa1c10', 'FEOR', '5293', 'Temetkezési foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-124f0b9b075a', 'FEOR', '5299', 'Egyéb, máshova nem sorolható szolgáltatási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1250f12e48b2', 'FEOR', '6', 'MEZŐGAZDASÁGI ÉS ERDŐGAZDÁLKODÁSI FOGLALKOZÁSOK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1251f336d2e9', 'FEOR', '61', 'Mezőgazdasági foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12523a71467d', 'FEOR', '611', 'Növénytermesztési foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12532a60871c', 'FEOR', '6111', 'Szántóföldinövény-termesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1254feb3e86e', 'FEOR', '6112', 'Bionövény-termesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1255968f3584', 'FEOR', '6113', 'Zöldségtermesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1256884bb3f3', 'FEOR', '6114', 'Szőlő-, gyümölcstermesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12579bc63ecf', 'FEOR', '6115', 'Dísznövény-, virág- és faiskolai kertész, csemetenevelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1258eebc804b', 'FEOR', '6116', 'Gyógynövénytermesztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12597ec4ad8d', 'FEOR', '6119', 'Egyéb növénytermesztési foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125aeef6a555', 'FEOR', '612', 'Állattenyésztési és állatgondozási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125b305351e8', 'FEOR', '6121', 'Szarvasmarha-, ló-, sertés-, juhtartó és -tenyésztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125cf97935c4', 'FEOR', '6122', 'Baromfitartó és -tenyésztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125d7a67d446', 'FEOR', '6123', 'Méhész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125e361a26a4', 'FEOR', '6124', 'Kisállattartó és -tenyésztő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-125fb5b5616e', 'FEOR', '613', 'Vegyes profilú gazdálkodók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1260542a3c0e', 'FEOR', '6130', 'Vegyes profilú gazdálkodó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12611c37071e', 'FEOR', '62', 'Erdőgazdálkodási, vadgazdálkodási és halászati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1262a8720595', 'FEOR', '621', 'Erdőgazdálkodási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1263a8eae949', 'FEOR', '6211', 'Erdészeti foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12641ffb8644', 'FEOR', '6212', 'Fakitermelő (favágó)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1265d367fbb6', 'FEOR', '622', 'Vadgazdálkodási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12665c24fd67', 'FEOR', '6220', 'Vadgazdálkodási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1267a13c58b1', 'FEOR', '623', 'Halászati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12680710ca01', 'FEOR', '6230', 'Halászati foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126957040107', 'FEOR', '7', 'IPARI ÉS ÉPÍTŐIPARI FOGLALKOZÁSOK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126ae8b2eae8', 'FEOR', '71', 'Élelmiszer-ipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126b2165fdb5', 'FEOR', '711', 'Élelmiszergyártók, -feldolgozók és -tartósítók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126ccc6110f8', 'FEOR', '7111', 'Húsfeldolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126dfdcf9965', 'FEOR', '7112', 'Gyümölcs- és zöldségfeldolgozó, -tartósító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126ec08e94b5', 'FEOR', '7113', 'Tejfeldolgozó, tejtermékgyártó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-126f94d383ce', 'FEOR', '7114', 'Pék, édesiparitermék-gyártó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1270bdae8c1e', 'FEOR', '7115', 'Borász és egyéb szeszesital-gyártó, szikvízkészítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1271df3ee09f', 'FEOR', '72', 'Könnyűipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-12726ad546ad', 'FEOR', '721', 'Ruha- és bőripari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127311f5faf5', 'FEOR', '7211', 'Szabásminta-készítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127455a49e94', 'FEOR', '7212', 'Szabó, varró');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127509b04989', 'FEOR', '7213', 'Kalapos, kesztyűs');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1276a0c361a6', 'FEOR', '7214', 'Szűcs, szőrmefestő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1277967ff904', 'FEOR', '7215', 'Tímár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127813a7cf62', 'FEOR', '7216', 'Bőrdíszműves, bőröndös, bőrtermékkészítő, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-1279b2a79a71', 'FEOR', '7217', 'Cipész, cipőkészítő, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127abfe2a1ad', 'FEOR', '722', 'aipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127b6bd61c03', 'FEOR', '7221', 'Famegmunkáló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da71-7e64-a729-127cc6327d91', 'FEOR', '7222', 'Faesztergályos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ac80dafe794', 'FEOR', '7223', 'Bútorasztalos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ac9e92e7f4b', 'FEOR', '7224', 'Kárpitos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aca68b104b9', 'FEOR', '7225', 'Kádár, bognár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1acb57f88821', 'FEOR', '723', 'Nyomdaipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1acc49e874aa', 'FEOR', '7231', 'Nyomdai előkészítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1acd02207bc8', 'FEOR', '7232', 'Nyomdász, nyomdai gépmester');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ace48bc287e', 'FEOR', '7233', 'Könyvkötő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1acf1f7c7301', 'FEOR', '73', 'Fém- és villamosipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad0da0dad56', 'FEOR', '731', 'Kohászati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad1173874f3', 'FEOR', '7310', 'Fémöntőminta-készítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad234c9e914', 'FEOR', '732', 'Fémmegmunkálók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad369461258', 'FEOR', '7321', 'Lakatos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad449eac33a', 'FEOR', '7322', 'Szerszámkészítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad5a4503272', 'FEOR', '7323', 'Forgácsoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad6632fed73', 'FEOR', '7324', 'Fémcsiszoló, köszörűs, szerszámköszörűs');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad718fbf47c', 'FEOR', '7325', 'Hegesztő, lángvágó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad8f8d73870', 'FEOR', '7326', 'Kovács');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ad9eb2f05fc', 'FEOR', '7327', 'Festékszóró, fényező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1adaf76f50d7', 'FEOR', '7328', 'Fém- és egyéb tartószerkezet-szerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1adb143f54ba', 'FEOR', '733', 'épek, berendezések karbantartói, javítói');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1adc7fe5689e', 'FEOR', '7331', 'Gépjármű- és motorkarbantartó, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1add837ae5a9', 'FEOR', '7332', 'Repülőgépmotor-karbantartó, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1adeea080644', 'FEOR', '7333', 'Mezőgazdasági és ipari gép (motor) karbantartója, javítója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1adf33267ea3', 'FEOR', '7334', 'Mechanikaigép-karbantartó, -javító (műszerész)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae0ed21a186', 'FEOR', '7335', 'Kerékpár-karbantartó, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae1387dc7d5', 'FEOR', '734', 'illamossági berendezések műszerészei, szerelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae2d400322e', 'FEOR', '7341', 'Villamos gépek és készülékek műszerésze, javítója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae31dd280b6', 'FEOR', '7342', 'Informatikai és telekommunikációs berendezések műszerésze, javítója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae43df83d0b', 'FEOR', '7343', 'Elektromoshálózat-szerelő, -javító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae59646601b', 'FEOR', '74', 'Kézműipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae65fe33cce', 'FEOR', '741', 'Kézműipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae737655981', 'FEOR', '7411', 'Címfestő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae84bedf8b0', 'FEOR', '7412', 'Ékszerkészítő, ötvös, drágakőcsiszoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1ae9939f1ac8', 'FEOR', '7413', 'Keramikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aeabad4f3bf', 'FEOR', '7414', 'Üveggyártó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aeb300d73cd', 'FEOR', '7415', 'Hangszerkészítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aec83fc11c4', 'FEOR', '7416', 'Szőr- és tollfeldolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aedca76dfbd', 'FEOR', '7417', 'Nád- és fűzfeldolgozó, seprű-, kefegyártó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aee38ebe39e', 'FEOR', '7418', 'Textilműves, hímző, csipkeverő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da72-70a6-a2a5-1aef371b762e', 'FEOR', '7419', 'Egyéb kézműipari foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0daef86b68d4', 'FEOR', '742', 'Finommechanikai műszerészek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0daf4a85644c', 'FEOR', '7420', 'Finommechanikai műszerész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db056c6dbb7', 'FEOR', '75', 'Építőipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db1ce3338b3', 'FEOR', '751', 'Építőmesteri foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db24c2b6a2e', 'FEOR', '7511', 'Kőműves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db38209847a', 'FEOR', '7512', 'Gipszkartonozó, stukkózó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db49685d288', 'FEOR', '7513', 'Ács');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db5e5d01a58', 'FEOR', '7514', 'Épületasztalos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db6d981e7bd', 'FEOR', '7515', 'Építményszerkezet-szerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db70e882957', 'FEOR', '7519', 'Egyéb építőmesteri foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db814f4f3a5', 'FEOR', '752', 'Építési, szerelési foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0db99d21e950', 'FEOR', '7521', 'Vezeték- és csőhálózat-szerelő (víz, gáz, fűtés)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dba93f0900a', 'FEOR', '7522', 'Szellőző-, hűtő- és klimatizálóberendezés-szerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dbb8272ecbe', 'FEOR', '7523', 'Felvonószerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dbc9b0a3674', 'FEOR', '7524', 'Épületvillamossági szerelő, villanyszerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dbd6fc4273c', 'FEOR', '7529', 'Egyéb építési, szerelési foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dbe4dfbfedd', 'FEOR', '753', 'Építési szakipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dbfb8852e79', 'FEOR', '7531', 'Szigetelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc0a60a4697', 'FEOR', '7532', 'Tetőfedő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc15cae1759', 'FEOR', '7533', 'Épület-, építménybádogos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc2b311bf61', 'FEOR', '7534', 'Burkoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc3213321b2', 'FEOR', '7535', 'Festő és mázoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc416bb9625', 'FEOR', '7536', 'Kőfaragó, műköves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc5d044c637', 'FEOR', '7537', 'Kályha- és kandallóépítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc673d4c786', 'FEOR', '7538', 'Üvegező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc7aff2b2c3', 'FEOR', '7539', 'Egyéb építési szakipari foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc8d60ead3d', 'FEOR', '79', 'Egyéb ipari és építőipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dc9cabab264', 'FEOR', '7911', 'Ipari búvár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dcaaa2fc748', 'FEOR', '7912', 'Ipari alpinista');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dcb4d1822fd', 'FEOR', '7913', 'Robbantómester');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dcc4246c951', 'FEOR', '7914', 'Kártevőirtó, gyomirtó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dcda9fe6352', 'FEOR', '7915', 'Kéményseprő, épületszerkezet-tisztító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dceb9f61f50', 'FEOR', '7919', 'Egyéb, máshova nem sorolható ipari és építőipari foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dcf31bb933e', 'FEOR', '8', 'GÉPKEZELŐK, ÖSSZESZERELŐK, JÁRMŰVEZETŐK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd0b2730d06', 'FEOR', '81', 'Feldolgozóipari gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd11b335aee', 'FEOR', '811', 'Élelmiszer-, ital-, dohánygyártó gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd207fc0ae0', 'FEOR', '8111', 'Élelmiszer-, italgyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd35f66fae3', 'FEOR', '8112', 'Dohánygyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd4e15aba77', 'FEOR', '812', 'Könnyűipari gépek kezelői és gyártósor mellett dolgozók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd5ab1fcb99', 'FEOR', '8121', 'Textilipari gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd6ca928ee5', 'FEOR', '8122', 'Ruházati gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd702adc58a', 'FEOR', '8123', 'Bőrkikészítő és -feldolgozó gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd87fbbdda0', 'FEOR', '8124', 'Cipőgyártó gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dd91b286bac', 'FEOR', '8125', 'Fafeldolgozó gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dda222f78c7', 'FEOR', '8126', 'Papír- és cellulóztermék-gyártó gép kezelője és gyártósor mellett dolgozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0ddb53e39655', 'FEOR', '813', 'Vegyipari alapanyagot és terméket gyártók, gépkezelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0ddcb01fb0ca', 'FEOR', '8131', 'Kőolaj- és földgázfeldolgozó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dddd66e7d62', 'FEOR', '8132', 'Vegyi alapanyagot és terméket gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0ddefaf82d14', 'FEOR', '8133', 'Gyógyszergyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0ddf0117986b', 'FEOR', '8134', 'Műtrágya- és növényvédőszer-gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de06b335cbc', 'FEOR', '8135', 'Műanyagtermék-gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de125835809', 'FEOR', '8136', 'Gumitermékgyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de2b73c8079', 'FEOR', '8137', 'Fotó- és mozgófilmlaboráns');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de355ad86da', 'FEOR', '814', 'Alapanyaggyártó gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de43047263b', 'FEOR', '8141', 'Kerámiaipari terméket gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de542320172', 'FEOR', '8142', 'Üveget és üvegterméket gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de6345a1500', 'FEOR', '8143', 'Cement-, kő- és egyéb ásványianyag-feldolgozó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de7a59ddbdf', 'FEOR', '8144', 'Papíripari alapanyagot gyártó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de89042e02d', 'FEOR', '815', 'Fémfeldolgozó és -megmunkáló gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0de9bba217f9', 'FEOR', '8151', 'Fémfeldolgozó gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dea75539b9b', 'FEOR', '8152', 'Fémmegmunkáló, felületkezelő gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0debdd48e58a', 'FEOR', '819', 'Egyéb feldolgozóipari gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0deca2d48e56', 'FEOR', '8190', 'Egyéb, máshova nem sorolható feldolgozóipari gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dedad4b5a95', 'FEOR', '82', 'Összeszerelők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dee89d63dc3', 'FEOR', '8211', 'Mechanikaigép-összeszerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0def6ccc277a', 'FEOR', '8212', 'Villamosberendezés-összeszerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df034c0dd90', 'FEOR', '8219', 'Egyéb termék-összeszerelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df1c73f7dcb', 'FEOR', '83', 'Helyhez kötött gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df20a87f049', 'FEOR', '831', 'Bányászati gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df3b563764a', 'FEOR', '8311', 'Szilárdásvány-kitermelő gép kezelője (szén, kő)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df4dd549eae', 'FEOR', '8312', 'Kútfúró, mélyfúró gép kezelője (kőolaj, földgáz, víz)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df5cf8fb127', 'FEOR', '832', 'Egyéb, helyhez kötött gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df65d69fb25', 'FEOR', '8321', 'Energetikai gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df7b466fb5e', 'FEOR', '8322', 'Vízgazdálkodási gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df8e4b8e6aa', 'FEOR', '8323', 'Kazángépkezelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0df91cc69e60', 'FEOR', '8324', 'Sugármentesítő gép, berendezés kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dfa75e9825a', 'FEOR', '8325', 'Csomagoló-, palackozó- és címkézőgép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dfb25cb53c8', 'FEOR', '8326', 'Mozigépész, vetítőgépész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dfcb1a3a1ff', 'FEOR', '8327', 'Mosodai gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dfd9d0dcd6b', 'FEOR', '8329', 'Egyéb, máshova nem sorolható, helyhez kötött gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dfeb54aa141', 'FEOR', '84', 'Járművezetők és mobil gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0dffabcd3224', 'FEOR', '841', 'Járművezetők és kapcsolódó foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e00a4aa1514', 'FEOR', '8411', 'Mozdonyvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0128bff1c9', 'FEOR', '8412', 'Vasútijármű-vezetéshez kapcsolódó foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e027e1170ca', 'FEOR', '8413', 'Villamosvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e039f5ffc8b', 'FEOR', '8414', 'Metróvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0487121b99', 'FEOR', '8415', 'Trolibuszvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e05a272c872', 'FEOR', '8416', 'Személygépkocsi-vezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e06f2a36e8b', 'FEOR', '8417', 'Tehergépkocsi-vezető, kamionsofőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0762144677', 'FEOR', '8418', 'Autóbuszvezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e08d22e8890', 'FEOR', '8419', 'Egyéb járművezető és kapcsolódó foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e096f740103', 'FEOR', '842', 'Mobil gépek kezelői');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0afbab2466', 'FEOR', '8421', 'Mezőgazdasági, erdőgazdasági, növényvédő gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0bc8365c82', 'FEOR', '8422', 'Földmunkagép és hasonló könnyű- és nehézgép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0c01beca31', 'FEOR', '8423', 'Köztisztasági, településtisztasági gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0dca146bb9', 'FEOR', '8424', 'Daru, felvonó és hasonló anyagmozgató gép kezelője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0e152f22c7', 'FEOR', '8425', 'Targoncavezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e0f0703b7a8', 'FEOR', '843', 'Hajózási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1012df13a7', 'FEOR', '8430', 'Hajószemélyzet, kormányos, matróz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e11fb3effc8', 'FEOR', '9', 'SZAKKÉPZETTSÉGET NEM IGÉNYLŐ (EGYSZERŰ) FOGLALKOZÁSOK');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1282c49214', 'FEOR', '91', 'Takarítók és hasonló jellegű egyszerű foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e130350e16c', 'FEOR', '911', 'Takarítók és kisegítők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e140f55f994', 'FEOR', '9111', 'Háztartási takarító és kisegítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e15e92d2259', 'FEOR', '9112', 'Intézményi takarító és kisegítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e16bba1b3dc', 'FEOR', '9113', 'Kézi mosó, vasaló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1776aaba7a', 'FEOR', '9114', 'Járműtakarító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e18a79db978', 'FEOR', '9115', 'Ablaktisztító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e19f8138835', 'FEOR', '9119', 'Egyéb takarító és kisegítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1a0012ca7d', 'FEOR', '92', 'Egyszerű szolgáltatási, szállítási és hasonló foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1b60454849', 'FEOR', '921', 'Szemétgyűjtők és hasonló foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1cb423736e', 'FEOR', '9211', 'Szemétgyűjtő, utcaseprő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1d16805a47', 'FEOR', '9212', 'Hulladékosztályozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1eb7e95bcb', 'FEOR', '922', 'Szállítási foglalkozások és rakodók');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e1fb8ea55b2', 'FEOR', '9221', 'Pedálos vagy kézi hajtású gépek vezetője');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e20c89ecd79', 'FEOR', '9222', 'Állati erővel vont jármű hajtója');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da73-7986-8c19-0e212905b77e', 'FEOR', '9223', 'Rakodómunkás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1157c546e4', 'FEOR', '9224', 'Pultfeltöltő, árufeltöltő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1285a35477', 'FEOR', '9225', 'Kézi csomagoló');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c138345cecb', 'FEOR', '923', 'Egyéb egyszerű szolgáltatási és szállítási foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c14698462c4', 'FEOR', '9231', 'Portás, telepőr, egyszerű őr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1558b6d66c', 'FEOR', '9232', 'Mérőóra-leolvasó és hasonló egyszerű foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1684bdef6b', 'FEOR', '9233', 'Hivatalsegéd, kézbesítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c17528ec811', 'FEOR', '9234', 'Hordár, csomagkihordó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1823c63264', 'FEOR', '9235', 'Gyorséttermi eladó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c195c45588a', 'FEOR', '9236', 'Konyhai kisegítő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1ac2a58d61', 'FEOR', '9237', 'Háztartási alkalmazott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1bcb502725', 'FEOR', '9238', 'Parkolóőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1c493707fd', 'FEOR', '9239', 'Egyéb, máshova nem sorolható egyszerű szolgáltatási és szállítási foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1dad298704', 'FEOR', '93', 'Egyszerű ipari, építőipari, mezőgazdasági foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1e558b7110', 'FEOR', '931', 'Egyszerű ipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c1f3fe33e32', 'FEOR', '9310', 'Egyszerű ipari foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c208095cb28', 'FEOR', '932', 'Egyszerű építőipari foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c21d79a24d5', 'FEOR', '9321', 'Kubikos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c22b1df4215', 'FEOR', '9329', 'Egyéb egyszerű építőipari foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c2364c67370', 'FEOR', '933', 'Egyszerű mezőgazdasági, erdészeti, vadászati és halászati foglalkozások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c24ce96b957', 'FEOR', '9331', 'Egyszerű mezőgazdasági foglalkozású');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019406fd-da74-7118-a387-2c2586735a40', 'FEOR', '9332', 'Egyszerű erdészeti, vadászati és halászati foglalkozású');

DELETE FROM dictionary where code_type_did = 'LANGUAGE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-03e3-7adf-b9dd-4f72870fef78', 'LANGUAGE', 'DE', 'német');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-0eb0-7418-a856-4d46eff0d0bc', 'LANGUAGE', 'EN', 'angol');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-1612-71da-99b4-0cb61aa7b02d', 'LANGUAGE', 'HU', 'magyar');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-1612-71da-99b4-0cb61aa7b02e', 'LANGUAGE', 'SK', 'szlovák');

DELETE FROM dictionary where code_type_did = 'MEDICAL_EXAM_RESULT';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-2705-7574-ac47-d5a702518928', 'MEDICAL_EXAM_RESULT', 'SUITABLE', 'Alkalmas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-2e0e-77f5-9704-1c0013bf7ff1', 'MEDICAL_EXAM_RESULT', 'SUITABLE_WITH_RESTRICTIONS', 'Megszorításokkal alkalmas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-3416-7cbd-9611-ec15da8ebd42', 'MEDICAL_EXAM_RESULT', 'UNSUITABLE', 'Alkalmatlan');

DELETE FROM dictionary where code_type_did = 'MEDICAL_EXAM_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-4021-706c-bc0b-9f6ef6352d9a', 'MEDICAL_EXAM_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-4653-740c-ae2c-d9e11bb66e0b', 'MEDICAL_EXAM_STATUS', 'PLAN', 'Piszkozat');

DELETE FROM dictionary where code_type_did = 'METHOD_OF_TERMINATION';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-50f2-79f6-817a-2100a041a459', 'METHOD_OF_TERMINATION', 'COMMON_AGREEMENT', 'Közös megegyezéssel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-56ec-7f03-8fcf-ec33984b6516', 'METHOD_OF_TERMINATION', 'IMMEDIATE_RESIGNATION', 'Azonnali hatályú felmondással');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-5ca8-707e-b6d5-af6dda78b43e', 'METHOD_OF_TERMINATION', 'RESIGNATION', 'Felmondással');

DELETE FROM dictionary where code_type_did = 'OBLIGATION';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-6ab4-7b46-88f8-2a9ff0183f78', 'OBLIGATION', 'CONDITION', 'Feltétellel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-7101-7623-b4fe-5a07fcaa909f', 'OBLIGATION', 'N', 'Nem kötelező');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-7745-718e-b06f-6888dea3ad42', 'OBLIGATION', 'Y', 'Kötelező');

DELETE FROM dictionary where code_type_did = 'PARTNER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-8474-7454-9a65-a33b00433b5b', 'PARTNER_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-8a5e-7b57-9a1b-d5ef8621e4cc', 'PARTNER_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-8f3b-7b1b-8b4b-0f3b1f7b1b8b', 'PARTNER_STATUS', 'INCOMPLETE', 'Hiányos');

DELETE FROM dictionary where code_type_did = 'PARTNER_ROLE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-9660-7def-b074-5476e7bce22b', 'PARTNER_ROLE', 'SUPPLIER', 'Beszállító');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-9cd7-729f-b36c-69d61f7cd42a', 'PARTNER_ROLE', 'CUSTOMER', 'Vevő');

DELETE FROM dictionary where code_type_did = 'PAYROLL_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-a9a4-7448-ac8b-2daeb5c5554c', 'PAYROLL_TYPE', 'HOURLY_WAGE', 'Órabér');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-b1cb-76b3-9fa4-515c532a677d', 'PAYROLL_TYPE', 'MONTHLY_SALERY', 'Havibér');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-b838-72c7-8b84-ff2becae4314', 'PAYROLL_TYPE', 'PERFORMANCE_PAY', 'Teljesítménybér');

DELETE FROM dictionary where code_type_did = 'POSITION';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-c5b3-7e86-b0a5-213cfdbe950f', 'POSITION', 'ACCOUNTANT', 'könyvelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-cc26-7a1a-ac05-e0f4cd0cdd72', 'POSITION', 'HR_COLLEAGUE', 'munkaügyis');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-d57f-70a0-a162-f6cb8ce1a334', 'POSITION', 'REGIONAL_REPRESANTATIVE', 'területi képvíselő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-dbfe-7e50-a3bd-5681e5026cf4', 'POSITION', 'SECRETARY', 'titkár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940700-e292-7854-b7ba-06f406461d67', 'POSITION', 'WAREHAUSMAN', 'raktáros');

DELETE FROM dictionary where code_type_did = 'REASON';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-00c0-7da3-9183-4ca78d6d1cde', 'REASON', '1', 'Üzemi baleset');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-0760-7271-8f6b-bf416e349bd9', 'REASON', '2', 'Foglalkoztatási megbetegedés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-0d8b-7239-a16f-52f514a4239f', 'REASON', '3', 'Közúti baleset');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-1375-7945-856e-a2322ee9c77e', 'REASON', '4', 'Egyéb baleset');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-19aa-7cd3-afe6-741d0f781d6f', 'REASON', '5', 'Beteg gyermek ápolása');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-1f87-7e20-a6fe-13db040d67e6', 'REASON', '6', 'Szülés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-25b4-7fb6-824a-9a3cc5110314', 'REASON', '7', 'hatósági elkülönítés közegészségügyi okokból');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-2bcf-7d7d-a6b9-5044dca62012', 'REASON', '8', 'egyéb betegség');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-3192-774d-afec-40257ddb7acb', 'REASON', '9', 'veszélyeztetett terhesség');

DELETE FROM dictionary where code_type_did = 'SETTLEMENT_BASIS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-3fef-7561-8444-23cf703e259d', 'SETTLEMENT_BASIS', 'PERFORMANCE', 'Teljesítmény');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-462a-7950-a53b-333a24472f14', 'SETTLEMENT_BASIS', 'TIME_WORKED', 'Ledolgozott idő');

DELETE FROM dictionary where code_type_did = 'SETTLEMENT_FREQUENCY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-5370-7cc8-83ae-fdd878c41f45', 'SETTLEMENT_FREQUENCY', '15D', '15 naponként');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-5991-75fc-b8c0-7ca0fe416afe', 'SETTLEMENT_FREQUENCY', '1M', 'Havi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-5fc3-704e-9008-02d72e8ce660', 'SETTLEMENT_FREQUENCY', '1W', 'Heti');

DELETE FROM dictionary where code_type_did = 'STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-6c41-700d-9354-ae8b4bee0611', 'STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-73ec-709b-af7e-3cea53a2361e', 'STATUS', 'FINISHED', 'Befejezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-7a0e-7a7b-90a7-0e29c9bfcbdf', 'STATUS', 'ONGOING', 'Folyamatban');

DELETE FROM dictionary where code_type_did = 'TASK_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-85a6-7490-ba38-af261208d761', 'TASK_TYPE', 'OTHER', 'Egyéb');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-8ba7-7b31-87f9-a9e9991c6ed7', 'TASK_TYPE', 'STAIRS', 'Lépcső');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-92ac-7c2b-b89f-7171c17c94f8', 'TASK_TYPE', 'WALL', 'Fal');

DELETE FROM dictionary where code_type_did = 'TIME_USE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-a129-7279-b406-b1a4ce5239de', 'TIME_USE_TYPE', 'HOLIDAY', 'Szabadság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-a762-7245-a652-5ae99908f463', 'TIME_USE_TYPE', 'SICK_PAYED', 'Táppénz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-b1f2-7af4-b263-5e1ece13c632', 'TIME_USE_TYPE', 'WORK', 'Munka');

DELETE FROM dictionary where code_type_did = 'WORKER_NOTE_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-c266-7199-940a-b7e2fe10b19f', 'WORKER_NOTE_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-ca2b-7df9-b78f-af5ff1685c42', 'WORKER_NOTE_STATUS', 'INACTIVE', 'Inaktív');

DELETE FROM dictionary where code_type_did = 'WORKER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-d5e6-7fcd-afba-08bb361964dd', 'WORKER_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-dec7-795d-b65d-cb087ce8b754', 'WORKER_STATUS', 'COME_ON', 'GYES');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-e491-7a0a-8592-fe1224425529', 'WORKER_STATUS', 'DURING_EXIT', 'Kilépés alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-ea1b-7b4b-a29e-3ddc58958caa', 'WORKER_STATUS', 'INTERESTED', 'Érdeklődő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-ef64-774d-aa75-2b0f54b1a5ca', 'WORKER_STATUS', 'PROBATION', 'Próbaidős');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940701-f51b-7cf4-a464-95f84288d833', 'WORKER_STATUS', 'RESIGNED', 'Felmondott');

DELETE FROM dictionary where code_type_did = 'WORKING_TIME_SCHEDULE_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-030e-72b8-9874-086ce9154587', 'WORKING_TIME_SCHEDULE_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-0af2-7c7a-becd-4ac3a5cc53df', 'WORKING_TIME_SCHEDULE_STATUS', 'PLAN', 'Terv');

DELETE FROM dictionary where code_type_did = 'INVOICE_STATE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-1bca-7365-bd27-96a2d8e4b7cf', 'INVOICE_STATE', 'TERV', 'Tervezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-2248-7170-9e9e-3512eac4647c', 'INVOICE_STATE', 'ELLVAR', 'Ellenőrzésre vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-2803-7e42-a223-52af0fdaecb3', 'INVOICE_STATE', 'JAVVAR', 'Javításra vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-2d64-783d-a8a4-e94e4e560942', 'INVOICE_STATE', 'ROGZ', 'Rögzített');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-32fb-7ebb-9d36-2e3db6b01e5d', 'INVOICE_STATE', 'FINVAR', 'Számlázásra vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-3976-75b3-884d-6f103fa5e147', 'INVOICE_STATE', 'ELO', 'Élő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-4198-70bf-a4eb-54edfbb03bc3', 'INVOICE_STATE', 'RESZTELJ', 'Részteljesített');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-4796-721f-a045-c66a451995f3', 'INVOICE_STATE', 'RENDEZVE', 'Rendezve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-4ec8-7d06-8d0d-11874fe2287b', 'INVOICE_STATE', 'LEZART', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-54f8-7335-ad34-21f64f9b8578', 'INVOICE_STATE', 'ELUTASITOTT', 'Elutasított');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-5b3d-7000-bdb3-474b09f1dfbe', 'INVOICE_STATE', 'TOROLT', 'Törölt');

DELETE FROM dictionary where code_type_did = 'INVOICE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-795b-7214-8219-4bf27b7e1d23', 'INVOICE_TYPE', 'SZAM', 'Számla');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-80ab-7211-9332-a0eed2af9c3b', 'INVOICE_TYPE', 'STOR', 'Sztornó számla');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-861d-7f13-87cc-11ab80738670', 'INVOICE_TYPE', 'DIJB', 'Díjbekérő számla');

DELETE FROM dictionary where code_type_did = 'PAYMENT_METHOD';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c33-a123-7a22-b345-01ac432de000', 'PAYMENT_METHOD', 'CREDIT_CARD', 'Bankkártya');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c33-b234-7b33-c456-12bd543ef111', 'PAYMENT_METHOD', 'BANK_TRANSFER', 'Banki átutalás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c33-c345-736a-9408-5cd3e99dc222', 'PAYMENT_METHOD', 'PAYPAL', 'PayPal');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-950e-7688-9cce-0ac50dd650ed', 'PAYMENT_METHOD', 'CASH', 'Készpénz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-9f92-70fc-9ef4-696a03fecb0c', 'PAYMENT_METHOD', 'CHEQ', 'Csekk');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c33-d456-7d9b-9c77-003175234333', 'PAYMENT_METHOD', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'CURRENCY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-b076-7c23-b1bc-358b900dcc44', 'CURRENCY', 'HUF', 'Forint');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-b599-70be-bb40-3e5b38196e1b', 'CURRENCY', 'EUR', 'Euro');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-bb0c-7010-976a-b256ce811f49', 'CURRENCY', 'USD', 'US Dollár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-c0a1-7b4c-8f2d-5e3f9b6a0c3d', 'CURRENCY', 'GBP', 'Angol font');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-c65e-7792-b201-eb99933a1360', 'CURRENCY', 'CHF', 'Svájci frank');

DELETE FROM dictionary where code_type_did = 'TASK_RULE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-d354-73e7-aa8c-a2a85196c49a', 'TASK_RULE_TYPE', 'SENDER_REGEX', 'Feladó minta');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-d8e5-7187-ae32-41ca4d9aed99', 'TASK_RULE_TYPE', 'SUBJECT_REGEX', 'Subject minta');

DELETE FROM dictionary where code_type_did = 'BANK_ACCOUNT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-e6f8-7e74-b1b7-536d87d78c49', 'BANK_ACCOUNT_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-ed45-7216-8f2f-5e9e4180dd37', 'BANK_ACCOUNT_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940702-f39f-790a-b36b-010fbce42b96', 'BANK_ACCOUNT_STATUS', 'DELETED', 'Törölt');

DELETE FROM dictionary where code_type_did = 'SUPPLIER';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-02c3-730a-a7d9-7e5e3338c1bc', 'SUPPLIER', 'POWER', 'Power bizt.');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-092b-7484-b720-ce192f8b3d05', 'SUPPLIER', 'RIEL', 'RIEL');

DELETE FROM dictionary where code_type_did = 'VAT_PERIOD';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-15ac-76e1-8e40-92758d07c4ba', 'VAT_PERIOD', 'MONTHLY', 'Havi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-1c51-7dd8-82c9-e7106abb2e75', 'VAT_PERIOD', 'QUATERLY', 'Negyedéves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-23fd-756c-b107-9177b47064de', 'VAT_PERIOD', 'YEARLY', 'Éves');

DELETE FROM dictionary where code_type_did = 'PROJECT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-3327-7e56-8aed-1c56e1430fc2', 'PROJECT_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-3a4b-734e-be2f-ca21a87938c9', 'PROJECT_STATUS', 'FINISHED', 'Befejezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-4099-7f6b-bc34-e05aa22b44af', 'PROJECT_STATUS', 'ONGOING', 'Folyamatban');

DELETE FROM dictionary where code_type_did = 'CONTACT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-4db4-7aae-9e6d-2128bff35bbd', 'CONTACT_TYPE', 'EMAIL', 'Email');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-55a0-7e8c-be4b-6fef1034a9bd', 'CONTACT_TYPE', 'PHONE', 'Telefon');

DELETE FROM dictionary where code_type_did = 'QUALIFICATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-6c78-7a11-a0a6-e5b219dddda4', 'QUALIFICATION_TYPE', 'ACCOUNTANT', 'Könyvelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-7745-7c87-96cf-b02355fbb6e4', 'QUALIFICATION_TYPE', 'ARCHITECT', 'Építőmérnök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-7e89-7bc5-965e-cce3a9edfeef', 'QUALIFICATION_TYPE', 'CRANE_HANDLING', 'Darukezelés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-8449-7a79-a55d-720d7459dca9', 'QUALIFICATION_TYPE', 'DRIVING_CAR', 'Személyautó vezetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-8a25-7367-8575-2b5f42376b4d', 'QUALIFICATION_TYPE', 'ENGLISH_LANGUAGE', 'Angol');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-8fa4-75ed-bea5-524c6d85b030', 'QUALIFICATION_TYPE', 'FORKLIFT_DRIVING', 'Targoncavezetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-95a2-7e23-8c90-b1884e6bbcc3', 'QUALIFICATION_TYPE', 'GERMAN_LANGUAGE', 'Német');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-9bb6-75bd-b33d-cd61ad3d3dc2', 'QUALIFICATION_TYPE', 'HEAVY_OP', 'Nehézgépkezelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-a199-75a2-b8a0-9016ac2ef0ad', 'QUALIFICATION_TYPE', 'MASON', 'Kőműves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940703-a7d3-7827-9e52-542c922c755d', 'QUALIFICATION_TYPE', 'WOODWORKER', 'Asztalos');

DELETE FROM dictionary where code_type_did = 'CITIZENSHIP';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603938fff434', 'CITIZENSHIP', 'HU', 'Magyar');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603a5519ae81', 'CITIZENSHIP', 'DE', 'Német');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603ba97901cc', 'CITIZENSHIP', 'EN', 'Angol');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603cf912a30e', 'CITIZENSHIP', 'FR', 'Francia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603d57df8a11', 'CITIZENSHIP', 'IT', 'Olasz');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603e63e35d62', 'CITIZENSHIP', 'ES', 'Spanyol');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-603f078b3f8d', 'CITIZENSHIP', 'RO', 'Román');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-60405cd4304a', 'CITIZENSHIP', 'PL', 'Lengyel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6041791c487d', 'CITIZENSHIP', 'CZ', 'Cseh');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6042e287dcc2', 'CITIZENSHIP', 'SK', 'Szlovák');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6043203fb2b2', 'CITIZENSHIP', 'SI', 'Szlovén');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6044156a34b7', 'CITIZENSHIP', 'HR', 'Horvát');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-60459ae65180', 'CITIZENSHIP', 'RS', 'Szerb');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-60462240106a', 'CITIZENSHIP', 'BA', 'Bosnyák');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6047b2578122', 'CITIZENSHIP', 'ME', 'Montenegrói');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-60486651f799', 'CITIZENSHIP', 'XK', 'Koszovói');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-6049383c81f0', 'CITIZENSHIP', 'AL', 'Albán');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-604a4c4e3696', 'CITIZENSHIP', 'MK', 'Macedón');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-604b88f8c1b6', 'CITIZENSHIP', 'BG', 'Bolgár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-604c940a4c29', 'CITIZENSHIP', 'GR', 'Görög');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-604d129bf887', 'CITIZENSHIP', 'TR', 'Török');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-87ee-7aff-ac11-604e79726638', 'CITIZENSHIP', 'UR', 'Ukrán');

DELETE FROM dictionary where code_type_did = 'ADDRESS_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-b64f-7614-9230-91a04dabe660', 'ADDRESS_TYPE', 'RESIDENCE', 'Lakcím');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-b64f-7614-9230-91a1edf4f121', 'ADDRESS_TYPE', 'WORK', 'Munkahely');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-b64f-7614-9230-91a284333e34', 'ADDRESS_TYPE', 'PERMANENT', 'Állandó lakcím');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-b64f-7614-9230-91a3a7599a22', 'ADDRESS_TYPE', 'MAIL', 'Levelezési cím');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-b64f-7614-9230-91a4e58fd755', 'ADDRESS_TYPE', 'SITE', 'Telephely');

DELETE FROM dictionary where code_type_did = 'RIGHT_PARAMETER';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777a14c9add8', 'RIGHT_PARAMETER', '1', 'Új');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777bfa7997ff', 'RIGHT_PARAMETER', '2', 'Módosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777cabdb9a92', 'RIGHT_PARAMETER', '3', 'Törlés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777d6b1ed401', 'RIGHT_PARAMETER', '4', 'Megtekintés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777e68140678', 'RIGHT_PARAMETER', '5', 'Nyomtatás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-777f997416dd', 'RIGHT_PARAMETER', '6', 'Exportálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-778056b88a1e', 'RIGHT_PARAMETER', '7', 'Importálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940704-f708-751b-aa6b-7781497537ea', 'RIGHT_PARAMETER', '8', 'Mentés');

DELETE FROM dictionary where code_type_did = 'SETTING_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-1f40-764f-9938-a93a44939bfa', 'SETTING_TYPE', '1', 'Szöveges');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-1f40-764f-9938-a93b84ae487e', 'SETTING_TYPE', '2', 'Szám');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-1f40-764f-9938-a93c3e239b6a', 'SETTING_TYPE', '3', 'Dátum');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-1f40-764f-9938-a93d9c7df04a', 'SETTING_TYPE', '4', 'Logikai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-1f40-764f-9938-a93e2c8728bf', 'SETTING_TYPE', '5', 'Szöveg');

DELETE FROM dictionary where code_type_did = 'CONTRACT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-4985-79e8-8627-5f76a647ae79', 'CONTRACT_TYPE', '1', 'Munkaszerződés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-4985-79e8-8627-5f77a0380f15', 'CONTRACT_TYPE', '2', 'Szolgáltatási');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-4985-79e8-8627-5f788cb6baa2', 'CONTRACT_TYPE', '3', 'Megbízási');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-4985-79e8-8627-5f79def21249', 'CONTRACT_TYPE', '4', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'SUBJECT';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-6ae1-7c66-b13a-0ff3b6c717c6', 'SUBJECT', '1', 'Árajánlat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-6ae1-7c66-b13a-0ff424961f67', 'SUBJECT', '2', 'Szerződés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-6ae1-7c66-b13a-0ff5c01e1e0b', 'SUBJECT', '3', 'Számla');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-6ae1-7c66-b13a-0ff6a21f9726', 'SUBJECT', '4', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'VALIDITY_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-8577-7aca-abdc-7c90b3a61bbb', 'VALIDITY_TYPE', 'VALID', 'Érvényes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-8f04-7247-89d8-a83adcea44e5', 'VALIDITY_TYPE', 'EXPIRED', 'Lejárt');

DELETE FROM dictionary where code_type_did = 'PAYMENT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-9ae2-7017-a755-5616c6a6d4b3', 'PAYMENT_STATUS', 'PAID', 'Fizetett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-a20b-7c10-b77d-a8b883cbb58b', 'PAYMENT_STATUS', 'UNPAID', 'Kifizetetlen');

DELETE FROM dictionary where code_type_did = 'PROCESSING_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-ac9c-71e3-8d51-bada8c64d91e', 'PROCESSING_STATUS', 'DRAFT', 'Piszkozat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('019481b2-9e91-7281-9747-e50358d2c1cf', 'PROCESSING_STATUS', 'RECEIVED', 'Befogadott');

DELETE FROM dictionary where code_type_did = 'UNIT_OF_MEASURE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-d353-73ba-bac9-49de6fbe2a6f', 'UNIT_OF_MEASURE', 'KG', 'kg');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-d353-73ba-bac9-49df4a538f35', 'UNIT_OF_MEASURE', 'L', 'l');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-d353-73ba-bac9-49e02da3546a', 'UNIT_OF_MEASURE', 'M', 'm');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-d353-73ba-bac9-49e103cf18f2', 'UNIT_OF_MEASURE', 'DB', 'db');

DELETE FROM dictionary where code_type_did = 'WORKER_ASSIGNMENT_REQUEST';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05e8cc87a93c', 'WORKER_ASSIGNMENT_REQUEST', 'NEW', 'Új');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05e9d930b053', 'WORKER_ASSIGNMENT_REQUEST', 'MOD', 'Módosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05eaaa399fc6', 'WORKER_ASSIGNMENT_REQUEST', 'DEL', 'Törlés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05eb58b09101', 'WORKER_ASSIGNMENT_REQUEST', 'VIEW', 'Megtekintés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05ec431b56b9', 'WORKER_ASSIGNMENT_REQUEST', 'PRINT', 'Nyomtatás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05ed06dd693a', 'WORKER_ASSIGNMENT_REQUEST', 'EXP', 'Exportálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05eecd8a2ec7', 'WORKER_ASSIGNMENT_REQUEST', 'IMP', 'Importálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940705-f49c-7cac-a579-05efa74b5a3e', 'WORKER_ASSIGNMENT_REQUEST', 'SAVE', 'Mentés');

DELETE FROM dictionary where code_type_did = 'WORKSHEET_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9381b6ab3b2c', 'WORKSHEET_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9382c2611e42', 'WORKSHEET_STATUS', 'FINISHED', 'Befejezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-938365eb2ff2', 'WORKSHEET_STATUS', 'ONGOING', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9384a0b1c2f6', 'WORKSHEET_STATUS', 'DRAFT', 'Tervezet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9385c8b1f3a0', 'WORKSHEET_STATUS', 'REJECTED', 'Elutasított');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9386e0b1f4b4', 'WORKSHEET_STATUS', 'CANCELED', 'Törölt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-13ef-77d4-af60-9387f6b1f5c8', 'WORKSHEET_STATUS', 'ACCOUNTED', 'Elszámolt');

DELETE FROM dictionary where code_type_did = 'MATERIAL_USE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-309f-7924-828e-9534a39d8b2b', 'MATERIAL_USE', 'USED', 'Felhasznált');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-309f-7924-828e-9535e0d60b6c', 'MATERIAL_USE', 'DISMOUNTED', 'Leszerelt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-309f-7924-828e-953658ac2527', 'MATERIAL_USE', 'DISCARDED', 'Selejtezett');

DELETE FROM dictionary where code_type_did = 'MATERIAL_REASON';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-4be8-7abd-b8f7-87bd677388e4', 'MATERIAL_REASON', 'DAMAGED', 'Sérült');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-4be8-7abd-b8f7-87bea7b1b1b7', 'MATERIAL_REASON', 'LOST', 'Elveszett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-4be8-7abd-b8f7-87c0b1b1b1b1', 'MATERIAL_REASON', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'CLOSURE_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-59de-7f46-8271-2df713337fd5', 'CLOSURE_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-60dc-70ad-91a9-11c3967dae93', 'CLOSURE_STATUS', 'OPEN', 'Nyitott');

DELETE FROM dictionary where code_type_did = 'CLOSURE_ITEM_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-751f-7369-b876-af7873de9c5a', 'CLOSURE_ITEM_TYPE', 'WORKER', 'Munkavégzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01940706-7d5e-77dc-a509-4654103a4b58', 'CLOSURE_ITEM_TYPE', 'MATERIAL', 'Anyagfelhasználás');

DELETE FROM dictionary where code_type_did = 'MOVEMENT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0194402b-e5f3-7364-9913-ba00a36514db', 'MOVEMENT_TYPE', 'IN', 'Bevételezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0194402b-ffc4-764a-9352-1c9881385f67', 'MOVEMENT_TYPE', 'OUT', 'Kivételezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0194402c-15c1-7646-9bee-bea860a04360', 'MOVEMENT_TYPE', 'MOVE', 'Mozgatás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0194402c-292c-7cc0-8a05-6ee529a60bfc', 'MOVEMENT_TYPE', 'DISPOSAL', 'Selejtezés');

DELETE FROM dictionary where code_type_did = 'SYSTEM_PARAMETER_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c34-a123-7a22-b345-01ac432de000', 'SYSTEM_PARAMETER_TYPE', 'GENERAL', 'Általános');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c34-b234-7b33-c456-12bd543ef111', 'SYSTEM_PARAMETER_TYPE', 'COMMISSION', 'Jutalék');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c34-c345-736a-9408-5cd3e99dc222', 'SYSTEM_PARAMETER_TYPE', 'NOTIFICATION', 'Értesítés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c34-d456-7d9b-9c77-003175234333', 'SYSTEM_PARAMETER_TYPE', 'SECURITY', 'Biztonság');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c34-e567-73a9-9420-c173e3f8f444', 'SYSTEM_PARAMETER_TYPE', 'INTEGRATION', 'Integráció');

DELETE FROM dictionary where code_type_did = 'COMPLAINT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-a123-7a22-b345-01ac432de000', 'COMPLAINT_TYPE', 'SERVICE', 'Szolgáltatás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-b234-7b33-c456-12bd543ef111', 'COMPLAINT_TYPE', 'TECHNICAL', 'Technikai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-c345-736a-9408-5cd3e99dc222', 'COMPLAINT_TYPE', 'BILLING', 'Számlázás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-d456-7d9b-9c77-003175234333', 'COMPLAINT_TYPE', 'CARRIER', 'Fuvarozó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-e567-73a9-9420-c173e3f8f444', 'COMPLAINT_TYPE', 'CLIENT', 'Megbízó');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c35-f678-71a1-a123-45ef67895555', 'COMPLAINT_TYPE', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'COMPLAINT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-a123-7a22-b345-01ac432de000', 'COMPLAINT_STATUS', 'NEW', 'Új');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-b234-7b33-c456-12bd543ef111', 'COMPLAINT_STATUS', 'ASSIGNED', 'Hozzárendelve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-c345-736a-9408-5cd3e99dc222', 'COMPLAINT_STATUS', 'IN_PROGRESS', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-d456-7d9b-9c77-003175234333', 'COMPLAINT_STATUS', 'WAITING_FOR_INFO', 'Információra vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-e567-73a9-9420-c173e3f8f444', 'COMPLAINT_STATUS', 'RESOLVED', 'Megoldva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-f678-71a1-a123-45ef67895555', 'COMPLAINT_STATUS', 'CLOSED', 'Lezárva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c36-0789-7890-b573-4a18075b6666', 'COMPLAINT_STATUS', 'ESCALATED', 'Eszkalálva');

DELETE FROM dictionary where code_type_did = 'COMPLAINT_PRIORITY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c37-a123-7a22-b345-01ac432de000', 'COMPLAINT_PRIORITY', 'LOW', 'Alacsony');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c37-b234-7b33-c456-12bd543ef111', 'COMPLAINT_PRIORITY', 'MEDIUM', 'Közepes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c37-c345-736a-9408-5cd3e99dc222', 'COMPLAINT_PRIORITY', 'HIGH', 'Magas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c37-d456-7d9b-9c77-003175234333', 'COMPLAINT_PRIORITY', 'CRITICAL', 'Kritikus');

DELETE FROM dictionary where code_type_did = 'L2F_NOTIFICATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-a123-7a22-b345-01ac432de000', 'L2F_NOTIFICATION_TYPE', 'ASSIGNMENT', 'Megbízás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-b234-7b33-c456-12bd543ef111', 'L2F_NOTIFICATION_TYPE', 'OFFER', 'Ajánlat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-c345-736a-9408-5cd3e99dc222', 'L2F_NOTIFICATION_TYPE', 'COMMISSION', 'Jutalék');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-d456-7d9b-9c77-003175234333', 'L2F_NOTIFICATION_TYPE', 'RATING', 'Értékelés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-e567-73a9-9420-c173e3f8f444', 'L2F_NOTIFICATION_TYPE', 'COMPLAINT', 'Reklamáció');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-f678-71a1-a123-45ef67895555', 'L2F_NOTIFICATION_TYPE', 'SYSTEM', 'Rendszer');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c38-0789-7890-b573-4a18075b6666', 'L2F_NOTIFICATION_TYPE', 'NEWSLETTER', 'Hírlevél');

DELETE FROM dictionary where code_type_did = 'NOTIFICATION_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c39-a123-7a22-b345-01ac432de000', 'NOTIFICATION_STATUS', 'PENDING', 'Függőben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c39-b234-7b33-c456-12bd543ef111', 'NOTIFICATION_STATUS', 'SENT', 'Elküldve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c39-c345-736a-9408-5cd3e99dc222', 'NOTIFICATION_STATUS', 'DELIVERED', 'Kézbesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c39-d456-7d9b-9c77-003175234333', 'NOTIFICATION_STATUS', 'READ', 'Olvasva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c39-e567-73a9-9420-c173e3f8f444', 'NOTIFICATION_STATUS', 'FAILED', 'Sikertelen');

DELETE FROM dictionary where code_type_did = 'NOTIFICATION_CHANNEL';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c40-a123-7a22-b345-01ac432de000', 'NOTIFICATION_CHANNEL', 'EMAIL', 'Email');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c40-b234-7b33-c456-12bd543ef111', 'NOTIFICATION_CHANNEL', 'SMS', 'SMS');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c40-c345-736a-9408-5cd3e99dc222', 'NOTIFICATION_CHANNEL', 'PUSH', 'Push értesítés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c40-d456-7d9b-9c77-003175234333', 'NOTIFICATION_CHANNEL', 'IN_APP', 'Alkalmazáson belüli');

DELETE FROM dictionary where code_type_did = 'SYSTEM_USER_ROLE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-a123-7a22-b345-01ac432de000', 'SYSTEM_USER_ROLE', 'ADMIN', 'Adminisztrátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-b234-7b33-c456-12bd543ef111', 'SYSTEM_USER_ROLE', 'CUSTOMER_SUPPORT', 'Ügyfélszolgálat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-c345-736a-9408-5cd3e99dc222', 'SYSTEM_USER_ROLE', 'FINANCE', 'Pénzügy');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-d456-7d9b-9c77-003175234333', 'SYSTEM_USER_ROLE', 'VERIFICATION', 'Ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-e567-73a9-9420-c173e3f8f444', 'SYSTEM_USER_ROLE', 'MARKETING', 'Marketing');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c41-f678-71a1-a123-45ef67895555', 'SYSTEM_USER_ROLE', 'READONLY', 'Csak olvasás');

DELETE FROM dictionary where code_type_did = 'VERIFICATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-a123-7a22-b345-01ac432de000', 'VERIFICATION_TYPE', 'FMCSA', 'FMCSA ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-b234-7b33-c456-12bd543ef111', 'VERIFICATION_TYPE', 'US_COMPANY', 'USA cég ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-c345-736a-9408-5cd3e99dc222', 'VERIFICATION_TYPE', 'CA_COMPANY', 'Kanadai cég ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-d456-7d9b-9c77-003175234333', 'VERIFICATION_TYPE', 'US_PERSON', 'USA személy ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-e567-73a9-9420-c173e3f8f444', 'VERIFICATION_TYPE', 'CA_PERSON', 'Kanadai személy ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c42-f678-71a1-a123-45ef67895555', 'VERIFICATION_TYPE', 'MANUAL', 'Manuális ellenőrzés');

DELETE FROM dictionary where code_type_did = 'NEWSLETTER_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c43-a123-7a22-b345-01ac432de000', 'NEWSLETTER_TYPE', 'GENERAL', 'Általános');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c43-b234-7b33-c456-12bd543ef111', 'NEWSLETTER_TYPE', 'CARRIER', 'Fuvarozói');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c43-c345-736a-9408-5cd3e99dc222', 'NEWSLETTER_TYPE', 'CLIENT', 'Megbízói');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c43-d456-7d9b-9c77-003175234333', 'NEWSLETTER_TYPE', 'PROMOTIONAL', 'Promóciós');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c43-e567-73a9-9420-c173e3f8f444', 'NEWSLETTER_TYPE', 'SYSTEM_UPDATE', 'Rendszerfrissítés');

DELETE FROM dictionary where code_type_did = 'NEWSLETTER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c44-a123-7a22-b345-01ac432de000', 'NEWSLETTER_STATUS', 'DRAFT', 'Vázlat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c44-b234-7b33-c456-12bd543ef111', 'NEWSLETTER_STATUS', 'SCHEDULED', 'Ütemezve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c44-c345-736a-9408-5cd3e99dc222', 'NEWSLETTER_STATUS', 'SENDING', 'Küldés alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c44-d456-7d9b-9c77-003175234333', 'NEWSLETTER_STATUS', 'SENT', 'Elküldve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c44-e567-73a9-9420-c173e3f8f444', 'NEWSLETTER_STATUS', 'CANCELLED', 'Visszavonva');

DELETE FROM dictionary where code_type_did = 'ASSIGNMENT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-a123-7a22-b345-01ac432de000', 'ASSIGNMENT_STATUS', 'DRAFT', 'Vázlat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-b234-7b33-c456-12bd543ef111', 'ASSIGNMENT_STATUS', 'PUBLISHED', 'Publikált');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-c345-736a-9408-5cd3e99dc222', 'ASSIGNMENT_STATUS', 'IN_PROGRESS', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-d456-7d9b-9c77-003175234333', 'ASSIGNMENT_STATUS', 'COMPLETED', 'Teljesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-e567-73a9-9420-c173e3f8f444', 'ASSIGNMENT_STATUS', 'CANCELLED', 'Visszavonva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c25-f678-71a1-a123-45ef67895555', 'ASSIGNMENT_STATUS', 'EXPIRED', 'Lejárt');

DELETE FROM dictionary where code_type_did = 'ASSIGNMENT_PART_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c26-a123-7a22-b345-01ac432de000', 'ASSIGNMENT_PART_STATUS', 'AVAILABLE', 'Elérhető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c26-b234-7b33-c456-12bd543ef111', 'ASSIGNMENT_PART_STATUS', 'ASSIGNED', 'Hozzárendelve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c26-c345-736a-9408-5cd3e99dc222', 'ASSIGNMENT_PART_STATUS', 'IN_PROGRESS', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c26-d456-7d9b-9c77-003175234333', 'ASSIGNMENT_PART_STATUS', 'COMPLETED', 'Teljesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c26-e567-73a9-9420-c173e3f8f444', 'ASSIGNMENT_PART_STATUS', 'CANCELLED', 'Visszavonva');

DELETE FROM dictionary where code_type_did = 'CARGO_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-a123-7a22-b345-01ac432de000', 'CARGO_TYPE', 'GENERAL', 'Általános');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-b234-7b33-c456-12bd543ef111', 'CARGO_TYPE', 'REFRIGERATED', 'Hűtött');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-c345-736a-9408-5cd3e99dc222', 'CARGO_TYPE', 'HAZARDOUS', 'Veszélyes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-d456-7d9b-9c77-003175234333', 'CARGO_TYPE', 'OVERSIZED', 'Túlméretes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-e567-73a9-9420-c173e3f8f444', 'CARGO_TYPE', 'FRAGILE', 'Törékeny');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-f678-71a1-a123-45ef67895555', 'CARGO_TYPE', 'LIVESTOCK', 'Élőállat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-0789-7890-b573-4a18075b6666', 'CARGO_TYPE', 'VEHICLES', 'Járművek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c27-1890-70af-b28c-8712af447777', 'CARGO_TYPE', 'BULK', 'Ömlesztett');

DELETE FROM dictionary where code_type_did = 'OFFER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-a123-7a22-b345-01ac432de000', 'OFFER_STATUS', 'DRAFT', 'Vázlat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-b234-7b33-c456-12bd543ef111', 'OFFER_STATUS', 'SUBMITTED', 'Beküldve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-c345-736a-9408-5cd3e99dc222', 'OFFER_STATUS', 'UNDER_REVIEW', 'Elbírálás alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-d456-7d9b-9c77-003175234333', 'OFFER_STATUS', 'ACCEPTED', 'Elfogadva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-e567-73a9-9420-c173e3f8f444', 'OFFER_STATUS', 'REJECTED', 'Elutasítva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-f678-71a1-a123-45ef67895555', 'OFFER_STATUS', 'MODIFICATION_REQUESTED', 'Módosítás kérve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-0789-7890-b573-4a18075b6666', 'OFFER_STATUS', 'CONFIRMED', 'Visszaigazolva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-1890-70af-b28c-8712af447777', 'OFFER_STATUS', 'CANCELLED', 'Visszavonva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c29-2901-7b2b-2b2b-b2b2b2b2b888', 'OFFER_STATUS', 'EXPIRED', 'Lejárt');

DELETE FROM dictionary where code_type_did = 'MODIFICATION_RESPONSE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c30-a123-7a22-b345-01ac432de000', 'MODIFICATION_RESPONSE_TYPE', 'ACCEPTED', 'Elfogadva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c30-b234-7b33-c456-12bd543ef111', 'MODIFICATION_RESPONSE_TYPE', 'REJECTED', 'Elutasítva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c30-c345-736a-9408-5cd3e99dc222', 'MODIFICATION_RESPONSE_TYPE', 'COUNTER_OFFER', 'Ellenajánlat');

DELETE FROM dictionary where code_type_did = 'COMMISSION_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c31-a123-7a22-b345-01ac432de000', 'COMMISSION_STATUS', 'PENDING', 'Függőben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c31-b234-7b33-c456-12bd543ef111', 'COMMISSION_STATUS', 'INVOICED', 'Számlázva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c31-c345-736a-9408-5cd3e99dc222', 'COMMISSION_STATUS', 'PAID', 'Fizetve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c31-d456-7d9b-9c77-003175234333', 'COMMISSION_STATUS', 'OVERDUE', 'Lejárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c31-e567-73a9-9420-c173e3f8f444', 'COMMISSION_STATUS', 'CANCELLED', 'Törölve');

DELETE FROM dictionary where code_type_did = 'COMMISSION_RATE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c32-a123-7a22-b345-01ac432de000', 'COMMISSION_RATE_TYPE', 'FIXED', 'Fix összeg');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c32-b234-7b33-c456-12bd543ef111', 'COMMISSION_RATE_TYPE', 'PERCENTAGE', 'Százalékos');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c32-c345-736a-9408-5cd3e99dc222', 'COMMISSION_RATE_TYPE', 'MIXED', 'Vegyes');

DELETE FROM dictionary where code_type_did = 'CARRIER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c22-a123-7a22-b345-01ac432de000', 'CARRIER_STATUS', 'PENDING_APPROVAL', 'Jóváhagyásra vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c22-b234-7b33-c456-12bd543ef111', 'CARRIER_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c22-c345-736a-9408-5cd3e99dc222', 'CARRIER_STATUS', 'SUSPENDED', 'Felfüggesztett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c22-d456-7d9b-9c77-003175234333', 'CARRIER_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c22-e567-73a9-9420-c173e3f8f444', 'CARRIER_STATUS', 'BANNED', 'Kitiltott');

DELETE FROM dictionary where code_type_did = 'CLIENT_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c23-a123-7a22-b345-01ac432de000', 'CLIENT_STATUS', 'PENDING_APPROVAL', 'Jóváhagyásra vár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c23-b234-7b33-c456-12bd543ef111', 'CLIENT_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c23-c345-736a-9408-5cd3e99dc222', 'CLIENT_STATUS', 'SUSPENDED', 'Felfüggesztett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c23-d456-7d9b-9c77-003175234333', 'CLIENT_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('02967c23-e567-73a9-9420-c173e3f8f444', 'CLIENT_STATUS', 'BANNED', 'Kitiltott');

DELETE FROM dictionary where code_type_did = 'US_STATES';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7001-8001-1234567890ab', 'US_STATES', 'AL', 'Alabama');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7002-8002-1234567890ac', 'US_STATES', 'AK', 'Alaska');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7003-8003-1234567890ad', 'US_STATES', 'AZ', 'Arizona');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7004-8004-1234567890ae', 'US_STATES', 'AR', 'Arkansas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7005-8005-1234567890af', 'US_STATES', 'CA', 'California');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7006-8006-1234567890b0', 'US_STATES', 'CO', 'Colorado');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7007-8007-1234567890b1', 'US_STATES', 'CT', 'Connecticut');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7008-8008-1234567890b2', 'US_STATES', 'DE', 'Delaware');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7009-8009-1234567890b3', 'US_STATES', 'FL', 'Florida');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700a-800a-1234567890b4', 'US_STATES', 'GA', 'Georgia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700b-800b-1234567890b5', 'US_STATES', 'HI', 'Hawaii');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700c-800c-1234567890b6', 'US_STATES', 'ID', 'Idaho');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700d-800d-1234567890b7', 'US_STATES', 'IL', 'Illinois');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700e-800e-1234567890b8', 'US_STATES', 'IN', 'Indiana');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-700f-800f-1234567890b9', 'US_STATES', 'IA', 'Iowa');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7010-8010-1234567890ba', 'US_STATES', 'KS', 'Kansas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7011-8011-1234567890bb', 'US_STATES', 'KY', 'Kentucky');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7012-8012-1234567890bc', 'US_STATES', 'LA', 'Louisiana');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7013-8013-1234567890bd', 'US_STATES', 'ME', 'Maine');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7014-8014-1234567890be', 'US_STATES', 'MD', 'Maryland');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7015-8015-1234567890bf', 'US_STATES', 'MA', 'Massachusetts');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7016-8016-1234567890c0', 'US_STATES', 'MI', 'Michigan');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7017-8017-1234567890c1', 'US_STATES', 'MN', 'Minnesota');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7018-8018-1234567890c2', 'US_STATES', 'MS', 'Mississippi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7019-8019-1234567890c3', 'US_STATES', 'MO', 'Missouri');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701a-801a-1234567890c4', 'US_STATES', 'MT', 'Montana');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701b-801b-1234567890c5', 'US_STATES', 'NE', 'Nebraska');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701c-801c-1234567890c6', 'US_STATES', 'NV', 'Nevada');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701d-801d-1234567890c7', 'US_STATES', 'NH', 'New Hampshire');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701e-801e-1234567890c8', 'US_STATES', 'NJ', 'New Jersey');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-701f-801f-1234567890c9', 'US_STATES', 'NM', 'New Mexico');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7020-8020-1234567890ca', 'US_STATES', 'NY', 'New York');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7021-8021-1234567890cb', 'US_STATES', 'NC', 'North Carolina');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7022-8022-1234567890cc', 'US_STATES', 'ND', 'North Dakota');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7023-8023-1234567890cd', 'US_STATES', 'OH', 'Ohio');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7024-8024-1234567890ce', 'US_STATES', 'OK', 'Oklahoma');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7025-8025-1234567890cf', 'US_STATES', 'OR', 'Oregon');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7026-8026-1234567890d0', 'US_STATES', 'PA', 'Pennsylvania');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7027-8027-1234567890d1', 'US_STATES', 'RI', 'Rhode Island');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7028-8028-1234567890d2', 'US_STATES', 'SC', 'South Carolina');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7029-8029-1234567890d3', 'US_STATES', 'SD', 'South Dakota');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702a-802a-1234567890d4', 'US_STATES', 'TN', 'Tennessee');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702b-802b-1234567890d5', 'US_STATES', 'TX', 'Texas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702c-802c-1234567890d6', 'US_STATES', 'UT', 'Utah');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702d-802d-1234567890d7', 'US_STATES', 'VT', 'Vermont');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702e-802e-1234567890d8', 'US_STATES', 'VA', 'Virginia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-702f-802f-1234567890d9', 'US_STATES', 'WA', 'Washington');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7030-8030-1234567890da', 'US_STATES', 'WV', 'West Virginia');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7031-8031-1234567890db', 'US_STATES', 'WI', 'Wisconsin');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7032-8032-1234567890dc', 'US_STATES', 'WY', 'Wyoming');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('018fe5dc-aabb-7033-8033-1234567890dd', 'US_STATES', 'DC', 'District of Columbia');

DELETE FROM dictionary where code_type_did = 'DENOMINATION_AVAILABILITY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c22-a123-7a22-b345-01ac432de000', 'DENOMINATION_AVAILABILITY', 'COMMON', 'Gyakori');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c22-b234-7b33-c456-12bd543ef111', 'DENOMINATION_AVAILABILITY', 'STANDARD', 'Általános');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c22-c345-736a-9408-5cd3e99dc222', 'DENOMINATION_AVAILABILITY', 'RARE', 'Ritka');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c22-d456-7d9b-9c77-003175234333', 'DENOMINATION_AVAILABILITY', 'OBSOLETE', 'Elavult');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c22-e567-73a9-9420-c173e3f8f444', 'DENOMINATION_AVAILABILITY', 'SPECIAL', 'Speciális/Gyűjtői');

DELETE FROM dictionary where code_type_did = 'OPTIMIZATION_STRATEGY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-a123-71a1-a123-45ef6789a000', 'OPTIMIZATION_STRATEGY', 'GREEDY', 'Mohó algoritmus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-b234-7890-b573-4a18075ba111', 'OPTIMIZATION_STRATEGY', 'DYNAMIC', 'Dinamikus programozás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-c345-70af-b28c-8712af444222', 'OPTIMIZATION_STRATEGY', 'MIN_COINS', 'Minimum érme');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-d456-7f9f-955e-88b361f2d333', 'OPTIMIZATION_STRATEGY', 'MIN_BANKNOTES', 'Minimum bankjegy');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-e567-7a1a-1a1a-a1a1a1a1a444', 'OPTIMIZATION_STRATEGY', 'MIN_TOTAL', 'Minimum összes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-f678-7b2b-2b2b-b2b2b2b2b555', 'OPTIMIZATION_STRATEGY', 'CUSTOM', 'Egyedi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c23-0789-7c3c-3c3c-c3c3c3c3c666', 'OPTIMIZATION_STRATEGY', 'BRANCH_SPECIFIC', 'Pénztárspecifikus');

DELETE FROM dictionary where code_type_did = 'DENOMINATION_RULE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-a123-7a22-b345-01ac432d0000', 'DENOMINATION_RULE_TYPE', 'FIXED', 'Fix címletezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-b234-7b33-c456-12bd543e1111', 'DENOMINATION_RULE_TYPE', 'AMOUNT_BASED', 'Összeg alapú');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-c345-736a-9408-5cd3e99d2222', 'DENOMINATION_RULE_TYPE', 'CUSTOMER_TYPE', 'Ügyfél típus alapú');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-d456-7d9b-9c77-003175233333', 'DENOMINATION_RULE_TYPE', 'TRANSACTION_TYPE', 'Tranzakció típus alapú');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-e567-73a9-9420-c173e3f84444', 'DENOMINATION_RULE_TYPE', 'BRANCH_DEFAULT', 'Pénztár alapértelmezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-f678-71a1-a123-45ef67895555', 'DENOMINATION_RULE_TYPE', 'TIME_BASED', 'Időszak alapú');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-0789-7890-b573-4a18075b6666', 'DENOMINATION_RULE_TYPE', 'AVAILABILITY', 'Készlet alapú');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967c24-1890-70af-b28c-8712af447777', 'DENOMINATION_RULE_TYPE', 'PRIORITY', 'Prioritás alapú');

DELETE FROM dictionary where code_type_did = 'CURRENCY_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840560-a617-7c63-9e46-aff48f2b0724', 'CURRENCY_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840560-baa4-7740-94e8-bb686d7206ca', 'CURRENCY_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840560-cc61-7e3d-9fa0-0a52623782ab', 'CURRENCY_STATUS', 'SUSPENDED', 'Felfüggesztett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840560-d523-7e1f-a420-98765c429a0b', 'CURRENCY_STATUS', 'DEPRECATED', 'Kivezetett');

DELETE FROM dictionary where code_type_did = 'ROLE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-a0a0-7a0a-a0a0-a0a0a0a0a0a0', 'ROLE', 'ADMIN', 'Adminisztrátor');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-b0b0-7b0b-b0b0-b0b0b0b0b0b0', 'ROLE', 'MANAGER', 'Vezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-c0c0-7c0c-c0c0-c0c0c0c0c0c0', 'ROLE', 'CASHIER', 'Pénztáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-d0d0-7d0d-d0d0-d0d0d0d0d0d0', 'ROLE', 'SUPERVISOR', 'Felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-e0e0-7e0e-e0e0-e0e0e0e0e0e0', 'ROLE', 'AUDITOR', 'Ellenőr');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840566-f0f0-7f0f-f0f0-f0f0f0f0f0f0', 'ROLE', 'READONLY', 'Csak olvasás');

DELETE FROM dictionary where code_type_did = 'CLOSING_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840567-1111-7111-1111-111111111111', 'CLOSING_STATUS', 'OPEN', 'Nyitott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840567-2222-7222-2222-222222222222', 'CLOSING_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840567-3333-7333-3333-333333333333', 'CLOSING_STATUS', 'PROCESSING', 'Feldolgozás alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840567-4444-7444-4444-444444444444', 'CLOSING_STATUS', 'ERROR', 'Hibás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840567-5555-7555-5555-555555555555', 'CLOSING_STATUS', 'VERIFIED', 'Ellenőrzött');

DELETE FROM dictionary where code_type_did = 'PRIORITY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840571-a123-7a12-a123-a123a123a123', 'PRIORITY', 'CRITICAL', 'Kritikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840571-b234-7b23-b234-b234b234b234', 'PRIORITY', 'HIGH', 'Magas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840571-c345-7c34-c345-c345c345c345', 'PRIORITY', 'MEDIUM', 'Közepes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840571-d456-7d45-d456-d456d456d456', 'PRIORITY', 'LOW', 'Alacsony');

DELETE FROM dictionary where code_type_did = 'PERIOD';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-1a1a-71a1-1a1a-1a1a1a1a1a1a', 'PERIOD', 'DAILY', 'Napi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-2b2b-72b2-2b2b-2b2b2b2b2b2b', 'PERIOD', 'WEEKLY', 'Heti');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-3c3c-73c3-3c3c-3c3c3c3c3c3c', 'PERIOD', 'MONTHLY', 'Havi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-4d4d-74d4-4d4d-4d4d4d4d4d4d', 'PERIOD', 'QUARTERLY', 'Negyedéves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-5e5e-75e5-5e5e-5e5e5e5e5e5e', 'PERIOD', 'YEARLY', 'Éves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840573-6f6f-76f6-6f6f-6f6f6f6f6f6f', 'PERIOD', 'ONCE', 'Egyszeri');

DELETE FROM dictionary where code_type_did = 'APPROVAL_LEVEL';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840574-1212-7121-1212-121212121212', 'APPROVAL_LEVEL', 'CASHIER', 'Pénztáros');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840574-2323-7232-2323-232323232323', 'APPROVAL_LEVEL', 'SUPERVISOR', 'Felügyelő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840574-3434-7343-3434-343434343434', 'APPROVAL_LEVEL', 'MANAGER', 'Vezető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840574-4545-7454-4545-454545454545', 'APPROVAL_LEVEL', 'DIRECTOR', 'Igazgató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840574-5656-7565-5656-565656565656', 'APPROVAL_LEVEL', 'COMPLIANCE', 'Megfelelőségi tisztviselő');

DELETE FROM dictionary where code_type_did = 'OVERRIDE_REASON';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840575-abcd-7abc-abcd-abcdabcdabcd', 'OVERRIDE_REASON', 'SPECIAL_CUSTOMER', 'Kiemelt ügyfél');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b13-e4e0-798b-9980-5a3778c4d899', 'OVERRIDE_REASON', 'BUSINESS_NEED', 'Üzleti érdek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b14-602f-7f92-80c2-3e34d15682ff', 'OVERRIDE_REASON', 'MANAGEMENT_APPROVAL', 'Vezetői jóváhagyás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b14-839b-7e60-9b63-bd7696df4db0', 'OVERRIDE_REASON', 'ERROR_CORRECTION', 'Hibajavítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b14-a205-7c7b-842e-3f4d13acac86', 'OVERRIDE_REASON', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'RATE_MODIFICATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840580-1111-7111-1111-111111111111', 'RATE_MODIFICATION_TYPE', 'FIXED', 'Rögzített árfolyam');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b14-cc36-7823-87d3-9c998f93c3d6', 'RATE_MODIFICATION_TYPE', 'ADDITIVE', 'Összeadás (plusz/mínusz érték)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840580-3333-7333-3333-333333333333', 'RATE_MODIFICATION_TYPE', 'MULTIPLICATIVE', 'Szorzó (százalékos módosítás)');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840580-4444-7444-4444-444444444444', 'RATE_MODIFICATION_TYPE', 'DEFAULT', 'Alapértelmezett');

DELETE FROM dictionary where code_type_did = 'SESSION_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-aaaa-7aaa-aaaa-111111111111', 'SESSION_STATUS', 'OPEN', 'Nyitott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-bbbb-7bbb-bbbb-222222222222', 'SESSION_STATUS', 'CLOSED', 'Lezárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-cccc-7ccc-cccc-333333333333', 'SESSION_STATUS', 'PAUSED', 'Felfüggesztett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-dddd-7ddd-dddd-444444444444', 'SESSION_STATUS', 'BALANCED', 'Egyenlegben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-eeee-7eee-eeee-555555555555', 'SESSION_STATUS', 'UNBALANCED', 'Nem egyenlegben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840581-ffff-7fff-ffff-666666666666', 'SESSION_STATUS', 'ERROR', 'Hiba');

DELETE FROM dictionary where code_type_did = 'INVENTORY_LOG_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-a1a1-7a1a-a1a1-a1a1a1a1a1a1', 'INVENTORY_LOG_TYPE', 'SESSION_OPEN', 'Munkamenet nyitás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-b2b2-7b2b-b2b2-b2b2b2b2b2b2', 'INVENTORY_LOG_TYPE', 'SESSION_CLOSE', 'Munkamenet zárás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-c3c3-7c3c-c3c3-c3c3c3c3c3c3', 'INVENTORY_LOG_TYPE', 'TRANSACTION', 'Tranzakció');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-d4d4-7d4d-d4d4-d4d4d4d4d4d4', 'INVENTORY_LOG_TYPE', 'TRANSFER_IN', 'Pénzforgalom be');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-e5e5-7e5e-e5e5-e5e5e5e5e5e5', 'INVENTORY_LOG_TYPE', 'TRANSFER_OUT', 'Pénzforgalom ki');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840582-f6f6-7f6f-f6f6-f6f6f6f6f6f6', 'INVENTORY_LOG_TYPE', 'CORRECTION', 'Korrekció');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b15-49ca-7471-bc5e-b326ae9738a8', 'INVENTORY_LOG_TYPE', 'INVENTORY', 'Leltár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b15-5e58-7cf0-92a0-b833ef18fa64', 'INVENTORY_LOG_TYPE', 'ADJUSTMENT', 'Kiigazítás');

DELETE FROM dictionary where code_type_did = 'TRANSFER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-1111-7111-1111-111111111111', 'TRANSFER_STATUS', 'INITIATED', 'Kezdeményezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-2222-7222-2222-222222222222', 'TRANSFER_STATUS', 'IN_PROGRESS', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-3333-7333-3333-333333333333', 'TRANSFER_STATUS', 'COMPLETED', 'Befejezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-4444-7444-4444-444444444444', 'TRANSFER_STATUS', 'REJECTED', 'Elutasított');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-5555-7555-5555-555555555555', 'TRANSFER_STATUS', 'CANCELLED', 'Törölt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840583-6666-7666-6666-666666666666', 'TRANSFER_STATUS', 'ERROR', 'Hiba');

DELETE FROM dictionary where code_type_did = 'ACTION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-aaaa-7aaa-aaaa-aaaaaaaaaaaa', 'ACTION_TYPE', 'CREATE', 'Létrehozás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-bbbb-7bbb-bbbb-bbbbbbbbbbbb', 'ACTION_TYPE', 'UPDATE', 'Módosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-cccc-7ccc-cccc-cccccccccccc', 'ACTION_TYPE', 'DELETE', 'Törlés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-dddd-7ddd-dddd-dddddddddddd', 'ACTION_TYPE', 'VIEW', 'Megtekintés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-eeee-7eee-eeee-eeeeeeeeeeee', 'ACTION_TYPE', 'EXPORT', 'Exportálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840568-ffff-7fff-ffff-ffffffffffff', 'ACTION_TYPE', 'IMPORT', 'Importálás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b15-f4f2-733e-8133-9308ce0f10aa', 'ACTION_TYPE', 'LOGIN', 'Bejelentkezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-0970-757f-92ba-920163cc358e', 'ACTION_TYPE', 'LOGOUT', 'Kijelentkezés');

DELETE FROM dictionary where code_type_did = 'REPORT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-a1a1-7a1a-a1a1-a1a1a1a1a1a1', 'REPORT_TYPE', 'DAILY', 'Napi jelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-b2b2-7b2b-b2b2-b2b2b2b2b2b2', 'REPORT_TYPE', 'MONTHLY', 'Havi jelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-c3c3-7c3c-c3c3-c3c3c3c3c3c3', 'REPORT_TYPE', 'INVENTORY', 'Készletjelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-d4d4-7d4d-d4d4-d4d4d4d4d4d4', 'REPORT_TYPE', 'TRANSACTION', 'Tranzakciós jelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-e5e5-7e5e-e5e5-e5e5e5e5e5e5', 'REPORT_TYPE', 'CUSTOMER', 'Ügyféljelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840569-f6f6-7f6f-f6f6-f6f6f6f6f6f6', 'REPORT_TYPE', 'AUDIT', 'Audit jelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-2d53-7f58-bfee-e9697e5ec0ef', 'REPORT_TYPE', 'TAX', 'Adójelentés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-4071-7de3-b787-89fe021efe90', 'REPORT_TYPE', 'CUSTOM', 'Egyedi jelentés');

DELETE FROM dictionary where code_type_did = 'NOTIFICATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840570-a1b2-7a1b-a1b2-a1b2a1b2a1b2', 'NOTIFICATION_TYPE', 'SYSTEM', 'Rendszerüzenet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840570-c3d4-7c3d-c3d4-c3d4c3d4c3d4', 'NOTIFICATION_TYPE', 'ALERT', 'Figyelmeztetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840570-e5f6-7e5f-e5f6-e5f6e5f6e5f6', 'NOTIFICATION_TYPE', 'INFO', 'Információ');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-639a-7a01-907c-337094103a00', 'NOTIFICATION_TYPE', 'ERROR', 'Hiba');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-73e2-7779-877e-bb016cefa516', 'NOTIFICATION_TYPE', 'REMINDER', 'Emlékeztető');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-846b-7950-b747-b8eb883aa4fb', 'NOTIFICATION_TYPE', 'APPROVAL', 'Jóváhagyásra vár');

DELETE FROM dictionary where code_type_did = 'SYSTEM_PARAMETER_GROUP';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-a1a1-7a1a-a1a1-a1a1a1a1a1a1', 'SYSTEM_PARAMETER_GROUP', 'SECURITY', 'Biztonsági beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-b2b2-7b2b-b2b2-b2b2b2b2b2b2', 'SYSTEM_PARAMETER_GROUP', 'TRANSACTION', 'Tranzakciós beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-c3c3-7c3c-c3c3-c3c3c3c3c3c3', 'SYSTEM_PARAMETER_GROUP', 'NOTIFICATION', 'Értesítési beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-d4d4-7d4d-d4d4-d4d4d4d4d4d4', 'SYSTEM_PARAMETER_GROUP', 'REPORTING', 'Jelentéskészítési beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-e5e5-7e5e-e5e5-e5e5e5e5e5e5', 'SYSTEM_PARAMETER_GROUP', 'INTERFACE', 'Felhasználói felület beállításai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840588-f6f6-7f6f-f6f6-f6f6f6f6f6f6', 'SYSTEM_PARAMETER_GROUP', 'INTEGRATION', 'Integrációs beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-a96d-715f-ab7a-66ef17ea1a03', 'SYSTEM_PARAMETER_GROUP', 'BACKUP', 'Mentési beállítások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b16-b874-7ab8-9e15-414dc7b91ace', 'SYSTEM_PARAMETER_GROUP', 'SYSTEM', 'Rendszerbeállítások');

DELETE FROM dictionary where code_type_did = 'BRANCH_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196de8d-20a9-7b0a-9450-1d804a12d099', 'BRANCH_TYPE', 'PENZTAR', 'Pénztár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196de8d-3334-7bee-be4b-7e87f7c2755a', 'BRANCH_TYPE', 'ERTEKTAR', 'Értéktár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196de8d-3e4e-76e8-b389-ae47e12f21f9', 'BRANCH_TYPE', 'FOERTEKTAR', 'Főértéktár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196de8d-509c-70e1-b660-e1a13e8dc84f', 'BRANCH_TYPE', 'KOZPONT', 'Központ');

DELETE FROM dictionary where code_type_did = 'BRANCH_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e7ba-06d1-735a-9158-b3fb88c0e9bf', 'BRANCH_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e44d-5050-7ede-b093-1dc2d18a7ede', 'BRANCH_STATUS', 'OPEN', 'Nyitva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e44d-5fa2-7f35-977a-4c64cceafdf7', 'BRANCH_STATUS', 'PAUSED', 'Szüneteltetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e44d-69f1-7375-a7b7-8f056f7cec0e', 'BRANCH_STATUS', 'CLOSED', 'Zárva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e44d-746d-736f-a173-95cd9c41a5a2', 'BRANCH_STATUS', 'INACTIVE', 'Nem aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196e44d-7cc4-762d-84aa-ec6e9da44a00', 'BRANCH_STATUS', 'DELETED', 'Végleges zárás');

DELETE FROM dictionary where code_type_did = 'BRANCH_TRANSFER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-a1a1-7a1a-a1a1-a1a1a1a1a1a1', 'BRANCH_TRANSFER_STATUS', 'INITIATED', 'Kezdeményezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-b2b2-7b2b-b2b2-b2b2b2b2b2b2', 'BRANCH_TRANSFER_STATUS', 'APPROVED', 'Jóváhagyott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-c3c3-7c3c-c3c3-c3c3c3c3c3c3', 'BRANCH_TRANSFER_STATUS', 'PREPARING', 'Előkészítés alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-d4d4-7d4d-d4d4-d4d4d4d4d4d4', 'BRANCH_TRANSFER_STATUS', 'READY_FOR_PICKUP', 'Szállításra kész');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-e5e5-7e5e-e5e5-e5e5e5e5e5e5', 'BRANCH_TRANSFER_STATUS', 'IN_TRANSIT', 'Szállítás alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840584-f6f6-7f6f-f6f6-f6f6f6f6f6f6', 'BRANCH_TRANSFER_STATUS', 'DELIVERED', 'Kézbesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-67e7-762d-a3fa-e8fc08e29bb1', 'BRANCH_TRANSFER_STATUS', 'VERIFIED', 'Ellenőrizve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-7983-7c41-9b09-77cb8bec38c0', 'BRANCH_TRANSFER_STATUS', 'COMPLETED', 'Befejezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-894b-7516-8a59-435c73a92f5f', 'BRANCH_TRANSFER_STATUS', 'DISCREPANCY', 'Eltérés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-9772-70ee-a3aa-c8d1991a71c1', 'BRANCH_TRANSFER_STATUS', 'CANCELLED', 'Törölt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-a52c-79ad-b0e4-3e4608fc2403', 'BRANCH_TRANSFER_STATUS', 'REJECTED', 'Elutasított');

DELETE FROM dictionary where code_type_did = 'TRANSFER_EVENT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-1010-7101-1010-101010101010', 'TRANSFER_EVENT_TYPE', 'CREATED', 'Létrehozva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-2020-7202-2020-202020202020', 'TRANSFER_EVENT_TYPE', 'APPROVED', 'Jóváhagyva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-3030-7303-3030-303030303030', 'TRANSFER_EVENT_TYPE', 'PREPARED', 'Előkészítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-4040-7404-4040-404040404040', 'TRANSFER_EVENT_TYPE', 'DISPATCHED', 'Elindítva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-5050-7505-5050-505050505050', 'TRANSFER_EVENT_TYPE', 'PICKUP', 'Átvéve szállításra');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-6060-7606-6060-606060606060', 'TRANSFER_EVENT_TYPE', 'CHECKPOINT', 'Ellenőrzőponton áthaladt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-7070-7707-7070-707070707070', 'TRANSFER_EVENT_TYPE', 'ARRIVED', 'Megérkezett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-8080-7808-8080-808080808080', 'TRANSFER_EVENT_TYPE', 'RECEIVED', 'Átvéve a célfióknál');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-9090-7909-9090-909090909090', 'TRANSFER_EVENT_TYPE', 'COUNTED', 'Megszámolva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-a0a0-7a0a-a0a0-a0a0a0a0a0a0', 'TRANSFER_EVENT_TYPE', 'VERIFIED', 'Ellenőrizve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-b0b0-7b0b-b0b0-b0b0b0b0b0b0', 'TRANSFER_EVENT_TYPE', 'DISCREPANCY', 'Eltérés észlelve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-c0c0-7c0c-c0c0-c0c0c0c0c0c0', 'TRANSFER_EVENT_TYPE', 'RESOLVED', 'Eltérés rendezve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840585-d0d0-7d0d-d0d0-d0d0d0d0d0d0', 'TRANSFER_EVENT_TYPE', 'CANCELLED', 'Törölt');

DELETE FROM dictionary where code_type_did = 'TRANSFER_REASON';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-a111-7a11-a111-a111a111a111', 'TRANSFER_REASON', 'STOCK_BALANCING', 'Készletkiegyenlítés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-b222-7b22-b222-b222b222b222', 'TRANSFER_REASON', 'HIGH_DEMAND', 'Magas kereslet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-c333-7c33-c333-c333c333c333', 'TRANSFER_REASON', 'LOW_DEMAND', 'Alacsony kereslet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-d444-7d44-d444-d444d444d444', 'TRANSFER_REASON', 'SCHEDULED', 'Ütemezett szállítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-e555-7e55-e555-e555e555e555', 'TRANSFER_REASON', 'SPECIAL_REQUEST', 'Speciális kérés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840586-f666-7f66-f666-f666f666f666', 'TRANSFER_REASON', 'RETURNING_EXCESS', 'Többlet visszaküldése');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-e48f-7932-bf4e-22e87a5d8db9', 'TRANSFER_REASON', 'SECURITY_CONCERNS', 'Biztonsági megfontolások');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b17-f29d-7da8-a047-861a04fcdd2b', 'TRANSFER_REASON', 'BRANCH_OPENING', 'Fiókmegnyitás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-0214-763b-89ec-1e6dbe8a1adc', 'TRANSFER_REASON', 'BRANCH_CLOSING', 'Fiókbezárás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-1040-7906-aa46-637ad293501a', 'TRANSFER_REASON', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'SCHEDULE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-1111-7111-1111-111111111111', 'SCHEDULE_TYPE', 'DAILY', 'Napi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-2222-7222-2222-222222222222', 'SCHEDULE_TYPE', 'WEEKLY', 'Heti');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-3333-7333-3333-333333333333', 'SCHEDULE_TYPE', 'MONTHLY', 'Havi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-4444-7444-4444-444444444444', 'SCHEDULE_TYPE', 'QUARTERLY', 'Negyedéves');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-5555-7555-5555-555555555555', 'SCHEDULE_TYPE', 'ON_DEMAND', 'Igény szerint');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840587-6666-7666-6666-666666666666', 'SCHEDULE_TYPE', 'CUSTOM', 'Egyedi ütemezés');

DELETE FROM dictionary where code_type_did = 'TRANSACTION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840561-f721-7a22-b345-01ac432de567', 'TRANSACTION_TYPE', 'BUY', 'Vétel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840561-f832-7b33-c456-12bd543ef678', 'TRANSACTION_TYPE', 'SELL', 'Eladás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-82ee-736a-9408-5cd3e99dc5b1', 'TRANSACTION_TYPE', 'EXCHANGE', 'Átváltás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-9437-7d9b-9c77-003175234d28', 'TRANSACTION_TYPE', 'RETURN', 'Visszaváltás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-a39d-73a9-9420-c173e3f8fb7a', 'TRANSACTION_TYPE', 'CORRECTION', 'Korrekció');

DELETE FROM dictionary where code_type_did = 'TRANSACTION_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840562-a123-71a1-a123-45ef6789ab12', 'TRANSACTION_STATUS', 'COMPLETED', 'Teljesített');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-cbf8-7f04-be6a-275208dbc21b', 'TRANSACTION_STATUS', 'PENDING', 'Folyamatban');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-d9b2-7890-b573-4a18075bab22', 'TRANSACTION_STATUS', 'CANCELLED', 'Törölt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-eb6c-70af-b28c-8712af4445a6', 'TRANSACTION_STATUS', 'REJECTED', 'Elutasított');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b18-f9cc-7f9f-955e-88b361f2d811', 'TRANSACTION_STATUS', 'SUSPENDED', 'Felfüggesztett');

DELETE FROM dictionary where code_type_did = 'LIMIT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-a1a1-7a1a-1a1a-a1a1a1a1a1a1', 'LIMIT_TYPE', 'DAILY_PURCHASE', 'Napi vásárlási limit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-b2b2-7b2b-2b2b-b2b2b2b2b2b2', 'LIMIT_TYPE', 'DAILY_SALE', 'Napi eladási limit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-c3c3-7c3c-3c3c-c3c3c3c3c3c3', 'LIMIT_TYPE', 'TRANSACTION', 'Tranzakció limit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-d4d4-7d4d-4d4d-d4d4d4d4d4d4', 'LIMIT_TYPE', 'CUSTOMER', 'Ügyfél limit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-e5e5-7e5e-5e5e-e5e5e5e5e5e5', 'LIMIT_TYPE', 'CURRENCY', 'Devizanem limit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840572-f6f6-7f6f-6f6f-f6f6f6f6f6f6', 'LIMIT_TYPE', 'ANONYMOUS', 'Anonim tranzakció limit');

DELETE FROM dictionary where code_type_did = 'ADJUSTMENT_REASON';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-1234-7123-1234-123412341234', 'ADJUSTMENT_REASON', 'SHORTAGE', 'Hiány');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-2345-7234-2345-234523452345', 'ADJUSTMENT_REASON', 'SURPLUS', 'Többlet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-3456-7345-3456-345634563456', 'ADJUSTMENT_REASON', 'DAMAGE', 'Sérült');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-4567-7456-4567-456745674567', 'ADJUSTMENT_REASON', 'COUNTERFEIT', 'Hamis');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-5678-7567-5678-567856785678', 'ADJUSTMENT_REASON', 'TRANSFER_ERROR', 'Átutalási hiba');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-6789-7678-6789-678967896789', 'ADJUSTMENT_REASON', 'SYSTEM_ERROR', 'Rendszerhiba');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-7890-7789-7890-789078907890', 'ADJUSTMENT_REASON', 'RECONCILIATION', 'Egyeztetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840590-8901-7890-8901-890189018901', 'ADJUSTMENT_REASON', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'CUSTOMER_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840563-a000-7a00-a000-0000000aaa00', 'CUSTOMER_TYPE', 'IN_INDIVIDUAL', 'Belföldi magánszemély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840563-a111-7a11-a111-1111111aaa11', 'CUSTOMER_TYPE', 'OUT_INDIVIDUAL', 'Külföldi magánszemély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840563-b222-7b22-b222-2222222bbb22', 'CUSTOMER_TYPE', 'CORPORATE', 'Jogi személy');

DELETE FROM dictionary where code_type_did = 'IDENTIFY_MODE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01040563-a111-7a11-a111-1111111aaa11', 'IDENTIFY_MODE', 'NOT_IDENTIFY', 'Nem azonosít');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01040563-b222-7b22-b222-2222222bbb22', 'IDENTIFY_MODE', 'FULL', 'Teljes azonosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01040563-b333-7b33-b333-3333333bbb33', 'IDENTIFY_MODE', 'ANNOUNCEMENT', 'Bemondásos');

DELETE FROM dictionary where code_type_did = 'IDENTITY_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-a123-7a12-a123-123456789a12', 'IDENTITY_TYPE', 'ID_CARD', 'Személyi igazolvány');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-b234-7b23-b234-234567890b23', 'IDENTITY_TYPE', 'PASSPORT', 'Útlevél');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-c345-7c34-c345-345678901c34', 'IDENTITY_TYPE', 'DRIVING_LIC', 'Vezetői engedély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-d456-7d45-d456-456789012d45', 'IDENTITY_TYPE', 'RESIDENCE', 'Tartózkodási engedély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-e567-7e56-e567-567890123e56', 'IDENTITY_TYPE', 'TAX_ID', 'Adóazonosító igazolvány');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840564-f678-7f67-f678-678901234f67', 'IDENTITY_TYPE', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'NATIONALITY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a001-7a01-1001-a01a01a01a01', 'NATIONALITY', 'HUN', 'Magyar');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a002-7a02-1002-a02a02a02a02', 'NATIONALITY', 'AUT', 'Osztrák');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a003-7a03-1003-a03a03a03a03', 'NATIONALITY', 'GER', 'Német');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a004-7a04-1004-a04a04a04a04', 'NATIONALITY', 'ROU', 'Román');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a005-7a05-1005-a05a05a05a05', 'NATIONALITY', 'SVK', 'Szlovák');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a006-7a06-1006-a06a06a06a06', 'NATIONALITY', 'SRB', 'Szerb');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a007-7a07-1007-a07a07a07a07', 'NATIONALITY', 'UKR', 'Ukrán');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a008-7a08-1008-a08a08a08a08', 'NATIONALITY', 'GBR', 'Brit');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a009-7a09-1009-a09a09a09a09', 'NATIONALITY', 'USA', 'Amerikai');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840565-a010-7a10-1010-a10a10a10a10', 'NATIONALITY', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'DOCUMENT_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840576-1a2b-71a2-1a2b-1a2b1a2b1a2b', 'DOCUMENT_TYPE', 'ID_CARD', 'Személyi igazolvány');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840576-3c4d-73c4-3c4d-3c4d3c4d3c4d', 'DOCUMENT_TYPE', 'PASSPORT', 'Útlevél');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840576-5e6f-75e6-5e6f-5e6f5e6f5e6f', 'DOCUMENT_TYPE', 'DRIVING_LICENSE', 'Vezetői engedély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-7b9e-7e83-adda-5496f4bad3aa', 'DOCUMENT_TYPE', 'RESIDENCE_PERMIT', 'Tartózkodási engedély');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-89da-7320-b334-e26898583cfe', 'DOCUMENT_TYPE', 'ADDRESS_CARD', 'Lakcímkártya');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-907c-7f98-bee6-791e290837e1', 'DOCUMENT_TYPE', 'TAX_CARD', 'Adókártya');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-9693-76ec-bcd9-7369bbfab5d4', 'DOCUMENT_TYPE', 'COMPANY_REGISTRATION', 'Cégkivonat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-9c11-7c5f-80b3-9f3b3a271086', 'DOCUMENT_TYPE', 'AUTHORIZATION', 'Meghatalmazás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-a24a-71a9-b8ec-3675c6c1b15a', 'DOCUMENT_TYPE', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'AML_CHECK_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840577-aabb-7aab-aabb-aabbaabbaabb', 'AML_CHECK_TYPE', 'CUSTOMER_CHECK', 'Ügyfél ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840577-ccdd-7ccd-ccdd-ccddccddccdd', 'AML_CHECK_TYPE', 'TRANSACTION_CHECK', 'Tranzakció ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840577-eeff-7eef-eeff-eeffeeffeeff', 'AML_CHECK_TYPE', 'PEP_CHECK', 'Politikai kitettség ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-e5c8-72a7-af5a-a3ce97b0b951', 'AML_CHECK_TYPE', 'SANCTION_CHECK', 'Szankciós lista ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-ebf2-7c75-915e-9daca814c9c3', 'AML_CHECK_TYPE', 'TERRORIST_CHECK', 'Terrorista lista ellenőrzés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01967b1a-f209-7a80-86e7-d300ea42e2f5', 'AML_CHECK_TYPE', 'RISK_ASSESSMENT', 'Kockázatelemzés');

DELETE FROM dictionary where code_type_did = 'AML_CHECK_RESULT';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840578-1111-7111-1111-111111111111', 'AML_CHECK_RESULT', 'PASSED', 'Megfelelt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840578-2222-7222-2222-222222222222', 'AML_CHECK_RESULT', 'REJECTED', 'Elutasított');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840578-3333-7333-3333-333333333333', 'AML_CHECK_RESULT', 'PENDING', 'Függőben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840578-4444-7444-4444-444444444444', 'AML_CHECK_RESULT', 'REVIEW', 'Felülvizsgálat szükséges');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840578-5555-7555-5555-555555555555', 'AML_CHECK_RESULT', 'ESCALATED', 'Eszkalált');

DELETE FROM dictionary where code_type_did = 'RISK_LEVEL';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840579-aaaa-7aaa-aaaa-aaaa1111aaaa', 'RISK_LEVEL', 'LOW', 'Alacsony');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840579-bbbb-7bbb-bbbb-bbbb2222bbbb', 'RISK_LEVEL', 'MEDIUM', 'Közepes');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840579-cccc-7ccc-cccc-cccc3333cccc', 'RISK_LEVEL', 'HIGH', 'Magas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01840579-dddd-7ddd-dddd-dddd4444dddd', 'RISK_LEVEL', 'EXTREME', 'Extrém');

DELETE FROM dictionary where code_type_did = 'REPRESENTATIVE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968c15-a123-7a22-b345-01ac432de100', 'REPRESENTATIVE_TYPE', 'PERMANENT', 'Állandó meghatalmazott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968c15-b234-7b33-c456-12bd543ef200', 'REPRESENTATIVE_TYPE', 'TEMPORARY', 'Időszakos meghatalmazott');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968c15-c345-736a-9408-5cd3e99dc300', 'REPRESENTATIVE_TYPE', 'LEGAL_GUARDIAN', 'Törvényes képviselő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968c15-d456-7d9b-9c77-003175234400', 'REPRESENTATIVE_TYPE', 'POWER_OF_ATTORNEY', 'Ügyvédi meghatalmazás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968c15-e567-73a9-9420-c173e3f8f500', 'REPRESENTATIVE_TYPE', 'COMPANY_DELEGATE', 'Céges megbízott');

DELETE FROM dictionary where code_type_did = 'RELATIONSHIP_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-a123-71a1-a123-45ef6789a100', 'RELATIONSHIP_TYPE', 'FAMILY', 'Családtag');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-b234-7890-b573-4a18075ba200', 'RELATIONSHIP_TYPE', 'COLLEAGUE', 'Munkatárs');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-c345-70af-b28c-8712af444300', 'RELATIONSHIP_TYPE', 'FRIEND', 'Barát');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-d456-7f9f-955e-88b361f2d400', 'RELATIONSHIP_TYPE', 'PROFESSIONAL', 'Szakmai kapcsolat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-e567-7a1a-1a1a-a1a1a1a1a500', 'RELATIONSHIP_TYPE', 'BUSINESS', 'Üzleti kapcsolat');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968d16-f678-7b2b-2b2b-b2b2b2b2b600', 'RELATIONSHIP_TYPE', 'OTHER', 'Egyéb');

DELETE FROM dictionary where code_type_did = 'AUTHORIZATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968e17-a123-7a22-b345-01ac432d0100', 'AUTHORIZATION_TYPE', 'FULL', 'Teljes körű meghatalmazás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968e17-b234-7b33-c456-12bd543e0200', 'AUTHORIZATION_TYPE', 'LIMITED', 'Korlátozott meghatalmazás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968e17-c345-736a-9408-5cd3e99d0300', 'AUTHORIZATION_TYPE', 'WITHDRAWAL', 'Csak pénzfelvétel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968e17-d456-7d9b-9c77-003175230400', 'AUTHORIZATION_TYPE', 'EXCHANGE', 'Csak valutaváltás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968e17-e567-73a9-9420-c173e3f80500', 'AUTHORIZATION_TYPE', 'ADMINISTRATIVE', 'Csak ügyintézés');

DELETE FROM dictionary where code_type_did = 'AUTHORIZATION_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968f18-a123-71a1-a123-45ef67890100', 'AUTHORIZATION_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968f18-b234-7890-b573-4a18075b0200', 'AUTHORIZATION_STATUS', 'PENDING', 'Függőben');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968f18-c345-70af-b28c-8712af440300', 'AUTHORIZATION_STATUS', 'EXPIRED', 'Lejárt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968f18-d456-7f9f-955e-88b361f20400', 'AUTHORIZATION_STATUS', 'REVOKED', 'Visszavont');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01968f18-e567-7a1a-1a1a-a1a1a1a10500', 'AUTHORIZATION_STATUS', 'SUSPENDED', 'Felfüggesztett');

DELETE FROM dictionary where code_type_did = 'OPERATION_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-a123-7a22-b345-01ac432d0100', 'OPERATION_TYPE', 'WITHDRAWAL', 'Pénzfelvétel');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-b234-7b33-c456-12bd543e0200', 'OPERATION_TYPE', 'DEPOSIT', 'Pénzbefizetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-c345-736a-9408-5cd3e99d0300', 'OPERATION_TYPE', 'EXCHANGE', 'Valutaváltás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-d456-7d9b-9c77-003175230400', 'OPERATION_TYPE', 'DATA_CHANGE', 'Adatmódosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-e567-73a9-9420-c173e3f80500', 'OPERATION_TYPE', 'VIEW_HISTORY', 'Tranzakciótörténet lekérés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01969019-f678-71a1-a123-45ef67890600', 'OPERATION_TYPE', 'DOCUMENTATION', 'Dokumentáció igénylés');

DELETE FROM dictionary where code_type_did = 'REPRESENTATIVE_LOG_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-a123-7a22-b345-01ac432d0100', 'REPRESENTATIVE_LOG_TYPE', 'LOGIN', 'Bejelentkezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-b234-7b33-c456-12bd543e0200', 'REPRESENTATIVE_LOG_TYPE', 'LOGOUT', 'Kijelentkezés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-c345-736a-9408-5cd3e99d0300', 'REPRESENTATIVE_LOG_TYPE', 'TRANSACTION', 'Tranzakció végrehajtás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-d456-7d9b-9c77-003175230400', 'REPRESENTATIVE_LOG_TYPE', 'DATA_UPDATE', 'Adatmódosítás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-e567-73a9-9420-c173e3f80500', 'REPRESENTATIVE_LOG_TYPE', 'AUTH_CHANGE', 'Jogosultság változás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-f678-71a1-a123-45ef67890600', 'REPRESENTATIVE_LOG_TYPE', 'DOC_UPLOAD', 'Dokumentum feltöltés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('0196911a-0789-7890-b573-4a18075b0700', 'REPRESENTATIVE_LOG_TYPE', 'STATUS_CHANGE', 'Státusz változás');

DELETE FROM dictionary where code_type_did = 'FOOD_CATEGORY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000001', 'FOOD_CATEGORY', 'DAIRY', 'Tejtermékek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000002', 'FOOD_CATEGORY', 'MEAT', 'Húsok és húskészítmények');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000003', 'FOOD_CATEGORY', 'VEGETABLES', 'Zöldségek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000004', 'FOOD_CATEGORY', 'FRUITS', 'Gyümölcsök');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000005', 'FOOD_CATEGORY', 'GRAINS', 'Gabonafélék');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000006', 'FOOD_CATEGORY', 'BEVERAGES', 'Italok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000007', 'FOOD_CATEGORY', 'BAKERY', 'Pékáruk');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000008', 'FOOD_CATEGORY', 'FROZEN', 'Fagyasztott termékek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000009', 'FOOD_CATEGORY', 'CANNED', 'Konzerv termékek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000010', 'FOOD_CATEGORY', 'SWEETS', 'Édességek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000011', 'FOOD_CATEGORY', 'SPICES', 'Fűszerek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000012', 'FOOD_CATEGORY', 'OILS', 'Olajok és zsírok');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000013', 'FOOD_CATEGORY', 'SEAFOOD', 'Tengeri és édesvízi halak');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000014', 'FOOD_CATEGORY', 'ORGANIC', 'Bio termékek');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000015', 'FOOD_CATEGORY', 'SUPPLEMENTS', 'Táplálékkiegészítők');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0001-7001-8001-000000000016', 'FOOD_CATEGORY', 'OTHERS', 'Egyéb élelmiszerek');

DELETE FROM dictionary where code_type_did = 'SUPPLIER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000001', 'SUPPLIER_STATUS', 'ACTIVE', 'Aktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000002', 'SUPPLIER_STATUS', 'INACTIVE', 'Inaktív');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000003', 'SUPPLIER_STATUS', 'SUSPENDED', 'Felfüggesztett');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000004', 'SUPPLIER_STATUS', 'PENDING', 'Függőben lévő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000005', 'SUPPLIER_STATUS', 'BLACKLISTED', 'Feketelistás');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000006', 'SUPPLIER_STATUS', 'PREFERRED', 'Preferált');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0003-7001-8001-000000000007', 'SUPPLIER_STATUS', 'TRIAL', 'Próbaperiódusban');

DELETE FROM dictionary where code_type_did = 'ORDER_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000001', 'ORDER_STATUS', 'DRAFT', 'Tervezet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000002', 'ORDER_STATUS', 'PENDING', 'Függőben lévő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000003', 'ORDER_STATUS', 'CONFIRMED', 'Megerősített');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000004', 'ORDER_STATUS', 'IN_PROGRESS', 'Feldolgozás alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000005', 'ORDER_STATUS', 'SHIPPED', 'Kiszállítva');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000006', 'ORDER_STATUS', 'DELIVERED', 'Kézbesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000008', 'ORDER_STATUS', 'CANCELLED', 'Törölve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0004-7001-8001-000000000009', 'ORDER_STATUS', 'REJECTED', 'Elutasítva');

DELETE FROM dictionary where code_type_did = 'PRIORITY_LEVEL';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0005-7001-8001-000000000001', 'PRIORITY_LEVEL', 'LOW', 'Alacsony');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0005-7001-8001-000000000002', 'PRIORITY_LEVEL', 'NORMAL', 'Normál');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0005-7001-8001-000000000003', 'PRIORITY_LEVEL', 'HIGH', 'Magas');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0005-7001-8001-000000000004', 'PRIORITY_LEVEL', 'URGENT', 'Sürgős');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0005-7001-8001-000000000005', 'PRIORITY_LEVEL', 'CRITICAL', 'Kritikus');

DELETE FROM dictionary where code_type_did = 'PRICE_TYPE';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000001', 'PRICE_TYPE', 'STANDARD', 'Normál ár');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000002', 'PRICE_TYPE', 'WHOLESALE', 'Nagykereskedelmi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000003', 'PRICE_TYPE', 'RETAIL', 'Kiskereskedelmi');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000004', 'PRICE_TYPE', 'PROMOTIONAL', 'Akciós');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000005', 'PRICE_TYPE', 'CUSTOMER_SPECIFIC', 'Ügyfélspecifikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0006-7001-8001-000000000006', 'PRICE_TYPE', 'VOLUME_DISCOUNT', 'Mennyiségi kedvezmény');

DELETE FROM dictionary where code_type_did = 'DELIVERY_STATUS';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000001', 'DELIVERY_STATUS', 'DRAFT', 'Tervezet');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000002', 'DELIVERY_STATUS', 'PENDING', 'Függőben lévő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000003', 'DELIVERY_STATUS', 'IN_TRANSIT', 'Szállítás alatt');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000004', 'DELIVERY_STATUS', 'DELIVERED', 'Kézbesítve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000005', 'DELIVERY_STATUS', 'RECEIVED', 'Átvéve');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0011-7001-8001-000000000006', 'DELIVERY_STATUS', 'REJECTED', 'Elutasítva');

DELETE FROM dictionary where code_type_did = 'ALERT_LEVEL';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0012-7001-8001-000000000001', 'ALERT_LEVEL', 'INFO', 'Tájékoztató');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0012-7001-8001-000000000002', 'ALERT_LEVEL', 'WARNING', 'Figyelmeztetés');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0012-7001-8001-000000000003', 'ALERT_LEVEL', 'CRITICAL', 'Kritikus');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0012-7001-8001-000000000004', 'ALERT_LEVEL', 'URGENT', 'Sürgős');

DELETE FROM dictionary where code_type_did = 'CUSTOMER_CATEGORY';
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0014-7001-8001-000000000001', 'CUSTOMER_CATEGORY', 'REGULAR', 'Törzsügyfél');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0014-7001-8001-000000000002', 'CUSTOMER_CATEGORY', 'VIP', 'VIP ügyfél');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0014-7001-8001-000000000003', 'CUSTOMER_CATEGORY', 'WHOLESALE', 'Nagykereskedő');
INSERT INTO dictionary (id, code_type_did, code, description) VALUES ('01950001-0014-7001-8001-000000000004', 'CUSTOMER_CATEGORY', 'RETAIL', 'Kiskereskedő');

-- --------------------------------------------------------
-- Hoszt:                        127.0.0.1
-- Szerver verzió:               PostgreSQL 16.6 (Debian 16.6-1.pgdg110+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
-- Szerver OS:                   
-- HeidiSQL Verzió:              12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES  */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45553aadab3', 'személyi igazolvány', 'ID_CARD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45645510a78', 'jogosítvány', 'DRIVERS_LICENCE', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b457c200de47', 'TAJ kártya', 'SOCIAL_SECURITY_CARD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45802621901', 'adóigazolvány', 'TAX_CERTIFICATE', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b4597387be48', 'munkaszerződés', 'EMPLOYMENT_CONTRACT', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45ad1c75c0a', 'kiküldetési szerződés', 'SECONDMENT_CONTRACT', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45bc5297a49', 'autó használati megállapodás', 'CAR_USE_AGREEMENT', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45c831aea0c', 'A1', 'A1-es engedély', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45da58483d2', 'A1 igénylő', 'A1-es igénylő', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45e8ec5e52c', 'orvosi alkalmassági igazolás', 'MEDICAL_FITNESS_CERTIFICATE', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b45f9881aea9', 'OEP kiskönyv', 'OEP_BOOK', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b4602b091ead', 'Munka-baleseti jegyzőkönyv', 'MBJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46125910225', 'elsődleges munka-baleseti jegyzőkönyv', 'EMBJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b462a34121bb', 'módosító munka-baleseti jegyzőkönyv', 'MEMBJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b463c84517ac', 'lezáró munka-baleseti jegyzőkönyv', 'LEMBJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b4640911383f', 'Határozat üzemi balesetről', 'HUB', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b4659afa4733', 'Orvosi igazolás üzemi balesetről', 'OIUB', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b466c5d70e6e', 'Munkaképtelenséget nem eredményező üzemi balesetről bejelentő lap', 'BL1', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b467f6554806', 'Munkaképtelenséget nem eredményező üzemi balesetről jegyzőkönyv', 'MJR', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46883e863f0', 'Munkaképtelenséget nem eredményező üzemi balesetről határozat', 'MHA', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46929e7d961', 'Meghallgatási jegyzőkönyv', 'MHJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46a6ecafd32', 'Nem üzemi balesetről szóló nyilatkozat', 'NUBNNY', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46bc7251d61', 'Nem üzemi balesetről szóló jegyzőkönyv', 'NUBJ', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46c83da7bbc', 'Nem üzemi balesetről szóló határozat', 'NUBH', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46d4c32e4c2', 'Lelet', 'MEDICAL_RECORD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46eb9df8bda', 'Német lakcímbejelentő', 'NLCB', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b46f23e6ddd8', 'Német adószám igénylő', 'NAIG', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b470d56f7ea9', 'EUTAJ', 'EU_SOCIAL_SECURITY_CARD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b47154166c82', 'EU TAJ igénylő', 'EU_SOCIAL_SECURITY_CARD_DEMAND', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b472e7d544f7', 'NAV meghatalmazás', 'NAV_AUTHORISATION', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b473fbbb91fb', 'OEP nyilatkozat', 'OEP_NY', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b474fc26756c', 'OEP felszólítás', 'OEP_F', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b47575ee5bb1', 'ARD Quittung', 'ARD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b476958d0a36', 'M30 igazolás', 'm30', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b4772634fe77', 'Letíltásról határozat', 'LETH', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('01940840-59f2-7fa5-a282-b478319a9395', 'Kilépési papír', 'KIPA', null, null, null, null, null, null, null, null, null, null);
INSERT INTO document_rule (id, name, code, document_rule_id, subject_did, obligation_did, validity_type_did, validity, notification_before_expiry, template, valid_from_date, valid_to_date, interpretable_attributes) VALUES ('019468b6-aa10-77c0-8bae-626e257615ac', 'Lakcímkártya', 'ADDR_CARD', null, null, null, null, null, null, null, null, null, null);
INSERT INTO system_parameter (id, param_key, description, param_value, is_editable) VALUES ('01940840-b619-791f-ad2d-86386afe8252', 'PASSWORD_LENGTH', 'Jelszó minimálisan elvárt hossza', '5', false);
INSERT INTO system_parameter (id, param_key, description, param_value, is_editable) VALUES ('01940840-b619-791f-ad2d-86392e0f832f', 'PASSWORD_CHANGE_FREQUENCY', 'Jelszó módosítási gyakoriság', '1M', false);
INSERT INTO system_parameter (id, param_key, description, param_value, is_editable) VALUES ('01940840-b619-791f-ad2d-863aabc23a12', 'PASSWORD_LENGTH', 'PASSWORD_REPETITION_FREQUENCY', '50', false);

INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce6-7928-91a9-d3a276ff0241', '2025-01-01', 3, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7188-a3f5-29f39d9c6828', '2025-01-02', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7762-9c87-544053c4760d', '2025-01-03', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7069-a0ee-4242cdb5f10f', '2025-01-04', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-785d-ae03-53063673a313', '2025-01-05', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7f0a-914c-ffded0b09d17', '2025-01-06', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7f1f-85d3-6ed9de40e13b', '2025-01-07', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-746a-9f63-0f5ec5a7a574', '2025-01-08', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7f7d-a528-44bc98195227', '2025-01-09', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7c82-9a6b-eb3b5b492f8b', '2025-01-10', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7671-bd7d-0b6d9c617ddd', '2025-01-11', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7e40-b0a7-65ce2fee5643', '2025-01-12', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7b78-825f-b3871dd882ff', '2025-01-13', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7c79-bd89-958d558fb19c', '2025-01-14', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7b3e-a768-a080feca206a', '2025-01-15', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-732f-be39-6c19ced74228', '2025-01-16', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-776f-a10f-9fe1c498ca5b', '2025-01-17', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7b6a-a91d-dae112fc0cb5', '2025-01-18', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7126-a936-5ee84a2b9df9', '2025-01-19', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cce9-7f58-96a5-a9f2d90be42d', '2025-01-20', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7f6a-9422-4fe2100bd387', '2025-01-21', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7940-a0aa-abc32bf29a18', '2025-01-22', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-789d-9dcd-15787a981d8f', '2025-01-23', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-767a-a5f6-b5490f7f675e', '2025-01-24', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7e0a-b391-244d92e650f4', '2025-01-25', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7d64-8ce7-0fbd1102a42e', '2025-01-26', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7ff8-948d-c378442b4cdc', '2025-01-27', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7172-9579-5d163e69e514', '2025-01-28', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7f9b-b3e9-7d89d74c5a2d', '2025-01-29', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7e5c-8bcf-c38bee6de025', '2025-01-30', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-781a-96a9-9bd4ab9d5c1d', '2025-01-31', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7a7d-a4cc-9fbc9a35a195', '2025-02-01', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7103-abd3-13b4c93d43ac', '2025-02-02', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-778f-b49e-b5cac0b7c315', '2025-02-03', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-73fc-b08f-df32eb0f6004', '2025-02-04', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7c88-81c2-3515a951d2f4', '2025-02-05', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7e54-95d7-6a8dd83772ab', '2025-02-06', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-79be-9931-2e0edaaf0824', '2025-02-07', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-759f-b30c-0fbba97272a5', '2025-02-08', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7c94-8e40-6b247ac94065', '2025-02-09', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7bc9-9580-5bef96bf4a0b', '2025-02-10', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7b28-9f45-c419af56c125', '2025-02-11', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7d62-8a05-b17f087bc030', '2025-02-12', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-7053-b2f6-dcae5763b3c6', '2025-02-13', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccea-710c-bbf3-753979d2f832', '2025-02-14', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7e21-a35c-c6ab6592a501', '2025-02-15', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7165-93f5-2e2e3ffe3282', '2025-02-16', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7037-8c0c-71255d35a54f', '2025-02-17', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-71e0-b192-bb2e11d8e673', '2025-02-18', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-761a-922d-d081997774ea', '2025-02-19', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7f67-be83-a59782ff4898', '2025-02-20', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7d14-997f-da0eba407fea', '2025-02-21', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7345-ad1a-4407b34c6658', '2025-02-22', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7476-8100-60daa4fd4ff1', '2025-02-23', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-75e1-96d9-4ca3dc986305', '2025-02-24', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7f75-9e7a-bdbabb8b866a', '2025-02-25', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7d0f-90bf-675dc620d121', '2025-02-26', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7c2d-a132-d1f2c2d6fb4f', '2025-02-27', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7ed0-b993-6e8b670965eb', '2025-02-28', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7c2d-b6f5-fe26b7de0a5f', '2025-03-01', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-770b-95db-f7b642be3382', '2025-03-02', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-78a5-a19d-1ce0777dce76', '2025-03-03', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-79a6-940c-610617f943dd', '2025-03-04', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7871-8e06-36dcfcc4e5d0', '2025-03-05', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7d2b-9088-c7de01304007', '2025-03-06', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-72fe-8e4e-a535fe34c564', '2025-03-07', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7453-9da0-f448d380a7c6', '2025-03-08', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-73a1-89d8-c40faa79c7c4', '2025-03-09', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-73bf-850f-d975b4ee4130', '2025-03-10', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-776d-af4e-9a5670c3b919', '2025-03-11', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-723c-8135-df133d4e949c', '2025-03-12', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cceb-7b5d-891c-4d97023028df', '2025-03-13', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7628-b573-28f8e43f6415', '2025-03-14', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7fe5-80d6-3b2e4f7ff93a', '2025-03-15', 6, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-786f-9d5c-8760e176872c', '2025-03-16', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-781a-a164-84a2168a3f18', '2025-03-17', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7dd2-b138-c68732b390ce', '2025-03-18', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7ef7-b55b-a9ad91ee0885', '2025-03-19', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-728c-9b5f-7f6262683b4c', '2025-03-20', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7e9f-b922-bee401fd9982', '2025-03-21', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7b81-8129-478513973b8b', '2025-03-22', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-77ae-9de4-477c5b8f90d6', '2025-03-23', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-711d-8fe0-4e1b9397bd47', '2025-03-24', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7b2e-9af7-e903b77c3639', '2025-03-25', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7c49-bedb-36ce564efc6f', '2025-03-26', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7db2-a1b6-29f79c7c0da1', '2025-03-27', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-79e3-9a7b-1467bbda6dd6', '2025-03-28', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7b1b-958e-b7e6a0268f63', '2025-03-29', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-74a3-8b41-b23763746987', '2025-03-30', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7845-83ba-767d0889b6cc', '2025-03-31', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-704c-9898-56e04d879d13', '2025-04-01', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7f05-9cb6-f7f9dcdf927d', '2025-04-02', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-742a-b56b-cf7b58924435', '2025-04-03', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7c44-8701-686a496dcf67', '2025-04-04', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7a3c-ab78-7058833d0a9f', '2025-04-05', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7af0-b360-85541aca235b', '2025-04-06', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7514-9913-5fd7b20e2b79', '2025-04-07', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-79ff-afa5-7a68b460d1bd', '2025-04-08', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccec-7619-9048-668a2596f3cd', '2025-04-09', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-79b6-b5fb-b2bca2bcadeb', '2025-04-10', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7134-b946-2dbfe18b1a8a', '2025-04-11', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7f2a-8760-02e370a393f5', '2025-04-12', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7fac-974c-742ca797f7b8', '2025-04-13', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7e8a-a369-78d6e7d9c0e9', '2025-04-14', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-730f-99ed-1ef617ea7571', '2025-04-15', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7230-909b-7445f8c15f9a', '2025-04-16', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7e20-b86d-0ac587fdbe4f', '2025-04-17', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7efb-87dc-158511f3af1e', '2025-04-18', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7e88-857c-5b4c950d6c30', '2025-04-19', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-76b1-b812-1dda988b27e9', '2025-04-20', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7ba0-9eb7-a6c617d5f1e5', '2025-04-21', 1, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-78ed-84ff-4134a0552045', '2025-04-22', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7af6-babc-ff58502aea2e', '2025-04-23', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7982-868d-3a4784934197', '2025-04-24', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-762b-8662-d22723eea0e0', '2025-04-25', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7308-abb7-9bd979595803', '2025-04-26', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-70e6-af45-83c1c7222724', '2025-04-27', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7959-ab35-a873714dedc5', '2025-04-28', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7b53-b185-f43875d8f140', '2025-04-29', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cced-7af6-9cad-fd40f2b7c03b', '2025-04-30', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-75fc-a826-ae5263ace1f1', '2025-05-01', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-7bbb-9fb1-1eb6dc5d2e89', '2025-05-02', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-7793-8bc7-6c4a09da2f0e', '2025-05-03', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-7d9c-8202-d703a365db29', '2025-05-04', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-79a2-88b9-5d6c388551d2', '2025-05-05', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-79fc-8746-64d64b6706b7', '2025-05-06', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-759b-9003-8b040705d06a', '2025-05-07', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-7ff3-9a99-35c545c06f13', '2025-05-08', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccef-7502-a1e2-24492c0d4b34', '2025-05-09', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7bdb-a463-b0c58757aacb', '2025-05-10', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7fce-88ee-99e85c584a85', '2025-05-11', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7b68-a9c2-d5dcd92b8cbe', '2025-05-12', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7de2-8e2d-892a144bd7bf', '2025-05-13', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7f07-a372-ed6ccdd4fb25', '2025-05-14', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7395-ab06-e353df3f36a9', '2025-05-15', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-785a-a704-56a644622621', '2025-05-16', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7448-8462-a1c523f43d02', '2025-05-17', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7b83-b342-7f3220712e40', '2025-05-18', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7ccf-92f9-d3da76f9cd2a', '2025-05-19', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7548-a4a1-f33fd8ee4c03', '2025-05-20', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7abc-87d1-01761f7c82f7', '2025-05-21', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-79bd-916d-499043dca887', '2025-05-22', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-72d4-b9ee-94bee3558e26', '2025-05-23', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-77a2-9ab3-d66c94b5baf5', '2025-05-24', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-74c8-bb72-d4677a913b88', '2025-05-25', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7a02-8d9e-55df04c7a14f', '2025-05-26', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7296-9db7-8866f16ad087', '2025-05-27', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7874-9c81-8bf2ade2a36a', '2025-05-28', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-74a9-b4a5-8011a562a2a5', '2025-05-29', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7c28-8ff5-526edc5fed21', '2025-05-30', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7724-9d93-50fa1ed403eb', '2025-05-31', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7ef8-84f7-467bc4ab68fc', '2025-06-01', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7236-925d-80ae4b5f3c93', '2025-06-02', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-75ba-a0a1-f3e88aa353e9', '2025-06-03', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-76d2-9336-7e05bc5ea222', '2025-06-04', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf0-7d24-8866-ae86b5bbaa95', '2025-06-05', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7489-9a5e-f22259c47142', '2025-06-06', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-73d1-b194-af606f09d881', '2025-06-07', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7680-ab19-c2b417a2e8e6', '2025-06-08', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7746-b63f-2fa2b33ea507', '2025-06-09', 1, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7435-bfe4-d8158c00c2e9', '2025-06-10', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7852-b541-41ea4d597c95', '2025-06-11', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7f82-95b4-837fc37405fd', '2025-06-12', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-79d5-ab79-585f90556b22', '2025-06-13', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-709f-baeb-0006d77db581', '2025-06-14', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-72ba-b872-0ea5821a2444', '2025-06-15', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7f96-b512-b7e5b626845b', '2025-06-16', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7839-b9fb-36f1d16fe88d', '2025-06-17', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7765-aa81-c63adc7c4b19', '2025-06-18', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7fdd-b74a-fdf6dad4292b', '2025-06-19', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7ac0-9c93-ae4b569757de', '2025-06-20', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-70da-af89-7ac244085cda', '2025-06-21', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7b8e-8c25-49c9674c7631', '2025-06-22', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7aae-acc2-35ab14a9b68e', '2025-06-23', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-76da-98b7-eb8203f45e78', '2025-06-24', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7e77-a37a-5ce673f1e6e3', '2025-06-25', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-76f3-91bc-27877f0596c4', '2025-06-26', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7dff-a3ef-f14fa9c6901e', '2025-06-27', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-74dc-be68-962f5d8906fb', '2025-06-28', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-779d-b1c3-42de84a64ab9', '2025-06-29', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7465-b435-8476d8901c2c', '2025-06-30', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-70ff-af39-54934007bbeb', '2025-07-01', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7345-ba8a-fcefef6f7c66', '2025-07-02', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7bc8-a381-68a9ac4ab925', '2025-07-03', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-71b7-9ed5-011a736f1f54', '2025-07-04', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf1-7832-a884-79425f977e6c', '2025-07-05', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7e22-b899-98d767af2e22', '2025-07-06', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7aa9-80fa-d0bf95d68f7a', '2025-07-07', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7576-8939-78a147d2ff19', '2025-07-08', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-79ce-ba2f-6f97440ed2f7', '2025-07-09', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7859-bdd3-a3e818f507ec', '2025-07-10', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7591-93ba-da2a04ad1ab1', '2025-07-11', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-71f2-899e-e67d82677622', '2025-07-12', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7b1e-971f-5390653af230', '2025-07-13', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7efb-be2c-1814d59b268c', '2025-07-14', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7fac-a684-fee7d3041b53', '2025-07-15', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-790c-8e97-e7a1d8ea309d', '2025-07-16', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-71b8-b0d6-cf9494fb7979', '2025-07-17', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7bfd-beb1-01ca080fe1e0', '2025-07-18', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-75cc-b7c2-a05035e20d03', '2025-07-19', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-77ce-baec-ce874e5b9fba', '2025-07-20', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7016-82c9-b5b4a06620f9', '2025-07-21', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7f87-a859-63b3712bed29', '2025-07-22', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7d26-a1dc-60e6cffc68cb', '2025-07-23', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7152-8b05-a0b06a05d88c', '2025-07-24', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-70a7-996b-6934d17675ec', '2025-07-25', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7b3c-85fd-49f16f6bafea', '2025-07-26', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-752a-b61c-21e72e8e3e25', '2025-07-27', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7b23-ba1c-cd195a85f754', '2025-07-28', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7c35-83b6-3336aba75bbd', '2025-07-29', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7eac-82a3-254ed732a70d', '2025-07-30', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-768e-a5cd-1a613671d5cb', '2025-07-31', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-70b7-a041-b1168da6f711', '2025-08-01', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-721b-abb9-e8e69819eb66', '2025-08-02', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf2-7ffa-bb5f-88a49ac71e2f', '2025-08-03', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7c1e-aadb-07e10af909a8', '2025-08-04', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-752e-9360-fc9a1f764d54', '2025-08-05', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7269-93ec-c0ae3123f647', '2025-08-06', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-73dd-b0fb-0301d309eac8', '2025-08-07', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-70f3-a7d1-13e5dffd1f2f', '2025-08-08', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-754f-8ff2-c37653131539', '2025-08-09', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-70a2-9b22-a5da55441e5a', '2025-08-10', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-73ee-be28-2437227fa790', '2025-08-11', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7a2e-9f49-3b733b174b77', '2025-08-12', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7617-96cd-0fe26a531e3d', '2025-08-13', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7aa4-a0a8-029126b11556', '2025-08-14', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7846-8bb2-1f31fa19d255', '2025-08-15', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7b37-a5eb-ccefeeb0a8e3', '2025-08-16', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7322-a865-2099e759d8e9', '2025-08-17', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-72e7-bfe1-d72268ceaaf9', '2025-08-18', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-70c7-b592-1e26187b1d76', '2025-08-19', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-750d-9a92-554a5f26d99d', '2025-08-20', 3, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7ddb-b44a-c45dc1b27c5c', '2025-08-21', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7faa-b3fa-b0f48a5cb4f1', '2025-08-22', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7e1e-b419-511c546f8490', '2025-08-23', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7359-abc7-162264f2f2a0', '2025-08-24', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7570-8bba-fc9e780dc29e', '2025-08-25', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-7611-b81f-c072539a54d9', '2025-08-26', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-704f-be52-b5934c8c0e64', '2025-08-27', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf3-70e1-bcc6-495b627543e3', '2025-08-28', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7b3b-aa33-f7baad11d1b7', '2025-08-29', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7a2a-9340-51c3bfd84e1c', '2025-08-30', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-70ce-85e8-905eab71d960', '2025-08-31', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7716-b0cf-a92b8b80da37', '2025-09-01', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-707f-a5d1-32fd2e59f6d7', '2025-09-02', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7538-88b9-2cba13b27a62', '2025-09-03', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7c0c-8a8c-f9955d0c2494', '2025-09-04', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7efd-8748-808c01bddfba', '2025-09-05', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7767-9cd7-7c9d7a1d4338', '2025-09-06', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7fbf-b060-7cd729e57c53', '2025-09-07', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7491-aed6-81c25891c59a', '2025-09-08', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7149-8415-ca9df0668161', '2025-09-09', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-797b-b4cb-38c8ba347c84', '2025-09-10', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-709e-8e00-6cd7f95374ed', '2025-09-11', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccf4-7467-8e94-e1cafac80a0a', '2025-09-12', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfd-71da-bbf3-f4a6a7f055a6', '2025-09-13', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-77e4-baea-a27340f51213', '2025-09-14', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-70c2-9db1-e3c8d5bf753c', '2025-09-15', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7c6c-989e-a28254d78cf5', '2025-09-16', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7f8d-afe6-2ca1694eb78e', '2025-09-17', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7cb0-b2c3-7345174fc3b1', '2025-09-18', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-742f-8bee-50836c198d62', '2025-09-19', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7fec-b485-5e97582f17c6', '2025-09-20', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-72d5-8d7e-00b17ebe17a8', '2025-09-21', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-711e-ac70-96c85d0a0427', '2025-09-22', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-79c0-8fde-359edab35705', '2025-09-23', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-79cb-8149-92071cdfbf15', '2025-09-24', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-73d4-8ac8-d8c498fa6859', '2025-09-25', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7ef4-897d-b6eb3f7f9154', '2025-09-26', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-768c-b33f-883749f945e9', '2025-09-27', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7da8-b7ee-e307c26ada9a', '2025-09-28', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7b0a-a9ea-a54d2349c520', '2025-09-29', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-730b-a979-941d8305ca89', '2025-09-30', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7609-97cd-e1f45f3b2e3e', '2025-10-01', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7531-9c05-8dd6249c24c8', '2025-10-02', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7b4e-a218-0ff99a579194', '2025-10-03', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7ad2-b3b0-38cdc33f82d3', '2025-10-04', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-76a1-a9fc-9d65a83423c7', '2025-10-05', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccfe-7cba-832a-bd528fb08538', '2025-10-06', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-75d6-bb24-76ea6cccced6', '2025-10-07', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7177-a38a-c49d45dff45a', '2025-10-08', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7ff4-94cf-107285eece69', '2025-10-09', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7783-80af-d4f8d3ccff38', '2025-10-10', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7fef-ac38-5ddf9aab8d40', '2025-10-11', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7b6d-b61e-93f0721f69bf', '2025-10-12', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7926-b971-87dccb52ef75', '2025-10-13', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7c5a-8e53-b6269221f52e', '2025-10-14', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7047-8119-7364569b6587', '2025-10-15', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7eac-8b1a-5401a83781e0', '2025-10-16', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7a22-8faa-c9e3c0039e1d', '2025-10-17', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-70a9-a8e4-1e4fe296e53e', '2025-10-18', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-ccff-7738-a650-8d9ed9b069f3', '2025-10-19', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-79eb-9d56-e83da5aba8ad', '2025-10-20', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-73bf-a7b5-541f5b6ea904', '2025-10-21', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7225-b45f-bb03f6086d17', '2025-10-22', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-72ce-b56a-0330e0a0493f', '2025-10-23', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7903-982d-d01f3c8b8480', '2025-10-24', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7927-901b-973e28cff67c', '2025-10-25', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-71f7-a9dc-280d99ec8f3e', '2025-10-26', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7b70-aa71-42429a288bc9', '2025-10-27', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7da6-8e7e-1421ec75a226', '2025-10-28', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7c4a-8ed5-72b4ed144c4a', '2025-10-29', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-703c-8370-70a992d459c5', '2025-10-30', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-75d6-8303-0d9923f0237d', '2025-10-31', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-793d-9794-c5bb9ae61e06', '2025-11-01', 6, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-73bd-8b28-3918efe32355', '2025-11-02', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7c1e-85b9-987ac8940d95', '2025-11-03', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-70b0-aadf-e0a7033dd1d0', '2025-11-04', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7686-bca6-f05eb71e77dd', '2025-11-05', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7f70-9977-a22685a59eff', '2025-11-06', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd00-7b76-9c9b-6223dcfcd44b', '2025-11-07', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7d90-829f-90d79e36e469', '2025-11-08', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-724b-af94-f326a8b38792', '2025-11-09', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-70f0-a764-ee72cbc2bcf7', '2025-11-10', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7223-87bf-b92bac4686ae', '2025-11-11', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7607-b06a-83b3b8054fa8', '2025-11-12', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-748d-a95e-56dff16aae4d', '2025-11-13', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7faa-9541-69d004135013', '2025-11-14', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7fbe-9b97-d3d8717f758a', '2025-11-15', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7872-ac73-2aec7ac95b79', '2025-11-16', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7249-8799-35ee262cbdf7', '2025-11-17', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-71ca-8564-5cb9cd429151', '2025-11-18', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7040-8feb-7f16e3da06cd', '2025-11-19', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7fca-bfd3-1a29f26c1d8c', '2025-11-20', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7d85-8f65-d6a7e53774a8', '2025-11-21', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7983-9881-cf2b54be8bbc', '2025-11-22', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7ed0-b565-a2e9759be3a2', '2025-11-23', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-785d-ba36-443fb2bab988', '2025-11-24', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7598-ba20-6362a471dfbb', '2025-11-25', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7878-a11a-b6e3d015ec1a', '2025-11-26', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7608-b1ea-934bbd6f5957', '2025-11-27', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-730a-9de9-4b84acd5796b', '2025-11-28', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-74eb-b3fa-1116528c7e10', '2025-11-29', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-77bd-b105-abd0bf6a5e1e', '2025-11-30', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7ad4-9ef8-599ae0fe1b48', '2025-12-01', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7683-b929-57e7b10286e3', '2025-12-02', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-701d-bda5-ac13edaa4449', '2025-12-03', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-721e-8af9-08da6181688d', '2025-12-04', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7ca3-9fe3-c938a3406838', '2025-12-05', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd01-7636-aacb-65c955eb649d', '2025-12-06', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7b28-b527-e488d738c74d', '2025-12-07', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-79eb-8db0-aa4c1684bd04', '2025-12-08', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7e98-acd9-e4594b26a47b', '2025-12-09', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7c6e-80c9-e0c347fd98f0', '2025-12-10', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-77fc-b47d-38dc139f37b3', '2025-12-11', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7aed-ba16-9f6bb91dabd1', '2025-12-12', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7f1b-aca3-01454e00ba4d', '2025-12-13', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7d75-8e2c-fd40f408d925', '2025-12-14', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7235-9172-83bd64e86056', '2025-12-15', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7738-8599-d20f397c9083', '2025-12-16', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7204-b1e0-b7a37624f47f', '2025-12-17', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-73af-a201-3b82e233440a', '2025-12-18', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-765a-87a9-9d00b30ca6c8', '2025-12-19', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7730-bbcb-2f58d4480742', '2025-12-20', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7160-8fc1-5a817b271829', '2025-12-21', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-755a-94b2-9f3740503a3c', '2025-12-22', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7738-8b1e-4fbca4cbf8ae', '2025-12-23', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7c51-91ac-11a730c584df', '2025-12-24', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7485-9f96-b701e4d49812', '2025-12-25', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7993-b46b-3e9e2a80a92c', '2025-12-26', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7b28-bb90-ac2ce1b53184', '2025-12-27', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd02-7836-8857-76fcbba8aaab', '2025-12-28', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7611-96d1-d750de0550d7', '2025-12-29', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-79d2-a8e6-cf4a858bedb1', '2025-12-30', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7db8-aa9f-cacc9646f8b0', '2025-12-31', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7c79-8d4e-3bb7c15ab3d1', '2026-01-01', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-790b-9b58-41459ba23de1', '2026-01-02', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-728a-a524-2c92f0c4418e', '2026-01-03', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-724d-ac69-8d8965176535', '2026-01-04', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7917-a70f-92376901de17', '2026-01-05', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7b97-b5b6-291827abb014', '2026-01-06', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-76fc-9cce-54b24919ae79', '2026-01-07', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7bdc-b9d2-50451a4a04ee', '2026-01-08', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7a49-a4e3-c3cc26bbb6b6', '2026-01-09', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-721c-9abf-1b6f67db780a', '2026-01-10', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7a03-b8ff-d25b7a986ff4', '2026-01-11', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-70ca-9b6a-928d230de136', '2026-01-12', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7cdc-98b4-883a49b55b53', '2026-01-13', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7f5b-9833-989021e14dc9', '2026-01-14', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-718b-9d65-c2172041e651', '2026-01-15', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7a6e-aef1-a418d703278a', '2026-01-16', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7533-8bd2-4a59140f6244', '2026-01-17', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-780d-a8fb-2e8e5ecb6ece', '2026-01-18', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7ccc-9b41-48a6bc100f5f', '2026-01-19', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7f15-b1e3-36ad344132dc', '2026-01-20', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7bcc-a04e-963126156632', '2026-01-21', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7851-8f08-7a56ff492f0e', '2026-01-22', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7e4a-af7a-81f0388c05a2', '2026-01-23', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-711f-99a2-16949dadf119', '2026-01-24', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd03-7a10-aa38-e933847c7863', '2026-01-25', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7f15-9ad4-d79ced3fffe5', '2026-01-26', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7bb0-861c-2a4d347b24a0', '2026-01-27', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-75e7-b780-c91b7a497e28', '2026-01-28', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7052-89a2-c1c91df2646d', '2026-01-29', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-72c1-9bea-6578ebfd4fc3', '2026-01-30', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-78ff-a3df-84e224af4b5a', '2026-01-31', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7a21-8e44-ef0b53f26409', '2026-02-01', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-73dc-8c83-0e628211e998', '2026-02-02', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7541-9cb8-584bc93e2bee', '2026-02-03', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7419-8f42-29196d542004', '2026-02-04', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-711e-908f-08e5ee629882', '2026-02-05', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7120-9537-d60132375d8e', '2026-02-06', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-76c7-a4bd-09aec0e1a412', '2026-02-07', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7eb1-ac4d-7257ee550355', '2026-02-08', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7ea9-87ef-71e9dd7cd6f0', '2026-02-09', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-746f-b2c2-c9a2a236ca98', '2026-02-10', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7ec4-97fa-1bfa62b3488f', '2026-02-11', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-74ec-a19f-443fda9d824f', '2026-02-12', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7ec8-a2a1-af62f664d67d', '2026-02-13', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-79d4-93d4-683edb943363', '2026-02-14', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7e9b-b9b5-c63b4fea3070', '2026-02-15', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-72b7-852c-821305fe6dee', '2026-02-16', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7ef0-aa9c-aedd10ab1fee', '2026-02-17', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7331-8a25-fa3377a7b828', '2026-02-18', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7bd7-b049-4d6fd760a6fa', '2026-02-19', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7cc8-9d7f-24858f6d2c21', '2026-02-20', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7d2b-9a90-01682937c38a', '2026-02-21', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7ac4-814f-34e797e9ad47', '2026-02-22', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd04-7774-a29d-9904f63723f4', '2026-02-23', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7801-9fe3-3a5daba6bc87', '2026-02-24', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7a09-ae58-8cc3679181db', '2026-02-25', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7f97-9a2c-5dcce5c62b70', '2026-02-26', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-72c1-baf7-babe8ae7dc47', '2026-02-27', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7b1e-b27e-1df71f5380e8', '2026-02-28', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-722a-bc85-1ac7f3366196', '2026-03-01', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7168-ba58-59c7cd780a5a', '2026-03-02', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-72ea-8a0c-d3ed54b49ac7', '2026-03-03', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7310-a396-5d4da3ca12ce', '2026-03-04', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-759d-a76b-c1976de01b61', '2026-03-05', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7994-ae22-bd874c10f7c5', '2026-03-06', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7811-b692-4b835bf8029d', '2026-03-07', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-79a4-9709-031cfd822dc9', '2026-03-08', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-736f-bf2d-51e5c35138c4', '2026-03-09', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-79ca-b0a8-18dd81552030', '2026-03-10', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-708a-a1ce-79f9d66654fe', '2026-03-11', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7efd-ab85-8ca29d858f32', '2026-03-12', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-75bb-a3f4-651cdaf65464', '2026-03-13', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7e46-b53c-c7afcc83a2f0', '2026-03-14', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7637-841d-b43e5399cf2e', '2026-03-15', 7, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7a55-81a7-22a23440e30e', '2026-03-16', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7609-9a3b-21613c153148', '2026-03-17', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7d36-8230-7269778fe73d', '2026-03-18', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7d65-a3ab-9ae72ac1aaa1', '2026-03-19', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-783f-bb33-a98fc7d1ae3e', '2026-03-20', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7840-99f8-23ea5934baff', '2026-03-21', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7e83-a012-e74d86a80a68', '2026-03-22', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7f1b-b7ca-183483a2e74d', '2026-03-23', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd05-7563-9acb-4eea4b3a4e50', '2026-03-24', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7b39-af4d-037e3cbcd63f', '2026-03-25', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-730a-86c3-95515bc0dbe8', '2026-03-26', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7841-8063-a4d59406cb74', '2026-03-27', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-74e1-b1a4-5ca97957bbd3', '2026-03-28', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7c3d-9961-51f3f944ef06', '2026-03-29', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7c60-9e36-b4adf0ebc521', '2026-03-30', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7792-a497-56b0af2db818', '2026-03-31', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-72d7-8595-f7381fc8bffd', '2026-04-01', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-757c-946a-60ec91d8ba9d', '2026-04-02', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7caf-a894-bdebf4987aad', '2026-04-03', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7d35-a6f8-05a19b8fff58', '2026-04-04', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-72b7-8b6c-0b65b0f1187c', '2026-04-05', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-718a-908d-831326696d17', '2026-04-06', 1, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-74ff-b29c-84f6c70b667c', '2026-04-07', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-717f-b5f0-c774f5ca9e8e', '2026-04-08', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7ac9-8db1-864639913761', '2026-04-09', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7179-bf7f-1349e7c0096a', '2026-04-10', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7128-91c1-42e4d51ab332', '2026-04-11', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-749e-896e-87bf5e931b18', '2026-04-12', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-77c4-b5dc-7ea9b2552ec4', '2026-04-13', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7557-831a-09f153ecc2b9', '2026-04-14', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7bcf-b247-4f75aaa0fb36', '2026-04-15', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7744-a8cf-a6489f4f2f2b', '2026-04-16', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7aa3-8fa1-f041f7f53e07', '2026-04-17', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-70a4-bb91-65e387d2b2e4', '2026-04-18', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd06-7c99-8e69-c2801918e912', '2026-04-19', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7461-adee-0c8853e6f3b3', '2026-04-20', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-73a3-9a14-6c45527c94ad', '2026-04-21', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7678-a310-fd3af9b9238f', '2026-04-22', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-73df-ba2c-0598ef520307', '2026-04-23', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-71a9-932a-c365a2821b16', '2026-04-24', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7d38-bb5c-97409fb93123', '2026-04-25', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-72d4-9f7e-b5f3ed1b1710', '2026-04-26', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7657-9346-e3e86c297e82', '2026-04-27', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7f14-a685-6ac2428641a9', '2026-04-28', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7532-9c67-035b7402f3d5', '2026-04-29', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7c2b-9f2a-aee73a9e16f7', '2026-04-30', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7fef-9536-49d2f0dd1298', '2026-05-01', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7889-8295-2a5a3720d34c', '2026-05-02', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-74c9-8df2-6eda9fad9c83', '2026-05-03', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7ba2-b8c7-96c8acd907ff', '2026-05-04', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-704a-a653-9c2cc8a1fde9', '2026-05-05', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-718b-bfec-4ab9760f394f', '2026-05-06', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7890-99b5-0b11241d77d5', '2026-05-07', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd07-7ef8-b03d-b86f96315c97', '2026-05-08', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-792a-843c-7437168a722e', '2026-05-09', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-719c-8de5-4cd0a7ceb208', '2026-05-10', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-771d-8625-8563bb778ef2', '2026-05-11', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7b7a-a912-7cfae9e54d7e', '2026-05-12', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-70cc-9f77-e528f89e276b', '2026-05-13', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7ba2-abc7-1292f6b0bace', '2026-05-14', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7070-b96c-c41bda5d8670', '2026-05-15', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7266-8022-3eec9af81ef8', '2026-05-16', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-70b2-9165-2367edffdade', '2026-05-17', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7fb9-865c-c1aaf643646d', '2026-05-18', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-71bf-bbcf-937410e98de9', '2026-05-19', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7e62-b6fc-da0254cd3dab', '2026-05-20', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7d19-b186-acb7538131dd', '2026-05-21', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-7a5b-b781-d7b8ebcc40b3', '2026-05-22', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-72fb-9469-f2266d6aa375', '2026-05-23', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-74e8-b976-e2bdf4a78b92', '2026-05-24', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-77fa-a6bd-5c81c7540bb5', '2026-05-25', 1, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd08-74a4-9163-f3c3544ca530', '2026-05-26', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7e82-9041-157b67f8cd62', '2026-05-27', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-73ad-85a7-c4ac01e2c4ad', '2026-05-28', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7494-94ce-b0d51fe5675b', '2026-05-29', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7c5a-b48a-36347eb9fcca', '2026-05-30', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7127-86bb-602d79655a8b', '2026-05-31', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7b63-be91-f6e42f2982d4', '2026-06-01', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-71ea-b9a4-716c9d7a358c', '2026-06-02', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-78a4-bdf2-8d105b8c8cc7', '2026-06-03', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-74dc-9c52-d058d91d1de2', '2026-06-04', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7781-97b4-51c3c0516876', '2026-06-05', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-73df-b06e-a490f6bea7f3', '2026-06-06', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7c6f-8a13-250e7198b381', '2026-06-07', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-791b-ad22-460ca897e060', '2026-06-08', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-7277-87d6-70770a2a8319', '2026-06-09', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0b-70db-8181-abe6978c463f', '2026-06-10', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-733a-819e-3ec6b36fe360', '2026-06-11', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-765d-b52c-be9d50691e08', '2026-06-12', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7d68-9a50-2e8264d93266', '2026-06-13', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-776a-8108-8063308115c4', '2026-06-14', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-712b-8b05-45b528be87dd', '2026-06-15', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-78a2-a2cc-565460edc025', '2026-06-16', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-76af-b28d-69dd718c259f', '2026-06-17', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7122-a927-ff7e635eebe7', '2026-06-18', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-78f8-beb8-047b27dfbd34', '2026-06-19', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7131-bf7a-c661d75d9756', '2026-06-20', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-768f-abed-67465120cdf4', '2026-06-21', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7a50-b323-82038aa8efb4', '2026-06-22', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7295-bf39-89e17fc12774', '2026-06-23', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7ab2-a894-3da84dae5efe', '2026-06-24', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7a0e-ae83-922b29bd5bb0', '2026-06-25', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-71ad-b654-01e71f371266', '2026-06-26', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-70ff-95d6-969fc2db48c5', '2026-06-27', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-770c-88f6-7ba5a6df1107', '2026-06-28', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7523-b0b3-fa514d3b8c25', '2026-06-29', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7e29-8a74-bcf2caf72f6b', '2026-06-30', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-727d-bf95-6506cc3a5737', '2026-07-01', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0c-7027-bc9c-401b4618ea4d', '2026-07-02', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-7643-811a-3d4673566df9', '2026-07-03', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-7d22-82f6-6e53b171aa22', '2026-07-04', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-74d5-acf1-f303cb3a26b1', '2026-07-05', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-7ccb-a555-d788332e6889', '2026-07-06', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-7a0a-905f-ccbacd93fefb', '2026-07-07', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0d-70fc-8d1b-b2e3eca18ba2', '2026-07-08', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-74ac-90de-52f7788cba32', '2026-07-09', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-716e-b3fa-f2e330967bc3', '2026-07-10', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7416-9ae3-0aa4ddc589ad', '2026-07-11', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7b88-aeda-5744c06e40e0', '2026-07-12', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7f0f-8b4f-7f130a2e4953', '2026-07-13', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7c39-bd12-57428fa9fe4d', '2026-07-14', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7233-b9ba-0be9c3c742fc', '2026-07-15', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-786c-ba98-de1cf6396d28', '2026-07-16', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-72a4-80f4-9b30f042236e', '2026-07-17', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-79ab-8999-e84c28c9c31b', '2026-07-18', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7e8b-83a0-0ddfdc64d4ad', '2026-07-19', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7df3-acec-b97b7a9015ea', '2026-07-20', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7c96-8054-a231ae7ee1c4', '2026-07-21', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-75d7-9152-1b9d3287fdbe', '2026-07-22', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7917-9814-95b49b794f38', '2026-07-23', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7013-b56b-7860e88ce900', '2026-07-24', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-715a-bf33-24cd531b5603', '2026-07-25', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7373-8a65-e2249f0602eb', '2026-07-26', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7532-a8dc-99571adbf57b', '2026-07-27', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0e-7c6e-a85f-7dffcd57f04f', '2026-07-28', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-735d-a702-1d0e045e7944', '2026-07-29', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7fc8-bf99-eec48300f6a3', '2026-07-30', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7578-a123-a3e26fefa4d7', '2026-07-31', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7312-81d3-67ea25fc9526', '2026-08-01', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7c71-8687-6565f81306af', '2026-08-02', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7799-976b-1275be935dd4', '2026-08-03', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-77ce-8aa1-af7494cdf72d', '2026-08-04', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7171-9dbb-af808188b122', '2026-08-05', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7314-b085-f69f51b73bf4', '2026-08-06', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7a7c-96d4-062c6a313dba', '2026-08-07', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7cc3-b45c-2dd0ed030fc4', '2026-08-08', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-740c-937a-bc3072fdc66e', '2026-08-09', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-745b-ae2d-a91408cbdad3', '2026-08-10', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7b8d-bcb5-705d68a1382e', '2026-08-11', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-79b6-8660-c93b1b53e01e', '2026-08-12', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7914-b18a-14d7bf2b461b', '2026-08-13', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7690-9d4c-ef0d90c28d60', '2026-08-14', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7404-9adc-b0762da7dcd8', '2026-08-15', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7f0c-b346-bb7fbefd013a', '2026-08-16', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7181-870e-0c1308e78ff8', '2026-08-17', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7226-9104-ece33246ef8d', '2026-08-18', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd0f-7fa0-93a9-d2b118552c05', '2026-08-19', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7e86-a821-e2c8ec2c8f1f', '2026-08-20', 4, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-73d4-a13b-4c12f3cd88e7', '2026-08-21', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-744b-9c77-5ac2ef954714', '2026-08-22', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-740c-896e-bb5b2c4aa887', '2026-08-23', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-70b0-b7ae-e0f15e125892', '2026-08-24', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7524-9cd8-cc76dcb5ff14', '2026-08-25', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7c9f-bed0-f380972b3145', '2026-08-26', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7655-9835-6d40cbdba64e', '2026-08-27', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7f6a-a5d1-21ba8089087e', '2026-08-28', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7156-b49a-5a0f068e7fe4', '2026-08-29', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-729e-8ab5-31bfa1cf288e', '2026-08-30', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-74bf-9d0e-077e6cc8f166', '2026-08-31', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-701c-a5a4-cf6c0430dce3', '2026-09-01', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-762e-8a45-06c1494da050', '2026-09-02', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-71ab-a9e3-00b00040b266', '2026-09-03', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-715c-96a3-ab4896e6de32', '2026-09-04', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7346-9177-482069444ab3', '2026-09-05', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-738c-9cb5-0aa2363cb615', '2026-09-06', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-75a0-afe5-e0bb7c8aaa6e', '2026-09-07', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-71a7-b0f0-c4b733de1035', '2026-09-08', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7ea1-a635-446c03487bbe', '2026-09-09', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7eaa-9760-c8956b774136', '2026-09-10', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7914-9d45-d13977c59841', '2026-09-11', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd10-7628-8be6-efe68ca74525', '2026-09-12', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-766b-8f0f-0c3c66688014', '2026-09-13', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7433-b412-be6ba4ad542f', '2026-09-14', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-74ea-9e4e-ec974919bb49', '2026-09-15', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7c93-b900-2c008c740eaf', '2026-09-16', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7bbf-ba04-dddd8a06b0e6', '2026-09-17', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-73bf-b813-60a29faa2118', '2026-09-18', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7391-9248-236d6fee8f03', '2026-09-19', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-712d-85d3-02cce90bad2c', '2026-09-20', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7c02-bdac-702ccc80863b', '2026-09-21', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-744d-b610-f21cb6b30760', '2026-09-22', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-799b-b5d7-262a33733210', '2026-09-23', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7ee8-b829-8f7030db44f5', '2026-09-24', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7b01-ad83-38d37fa9bbc6', '2026-09-25', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7b74-95ba-87e28d6cfe29', '2026-09-26', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7260-8353-310e5d28589c', '2026-09-27', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7abb-ae9d-a41a99da8015', '2026-09-28', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7fd0-b3af-4c5f489995e1', '2026-09-29', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-73d1-917d-9c8730b4f7d5', '2026-09-30', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-78b1-8a11-727c4f28a118', '2026-10-01', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7c22-bbf6-6e6bafb3e2cf', '2026-10-02', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7e40-8552-24a50864956d', '2026-10-03', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-747a-bc3f-8631f067e89f', '2026-10-04', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7b34-bf93-e31bb297484e', '2026-10-05', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-737a-a99a-456e1a9fe289', '2026-10-06', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-75c6-94eb-c94cd6f6c0cb', '2026-10-07', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-71b6-8402-e9ca683b6092', '2026-10-08', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7b72-b1ef-67c4dc2c7d09', '2026-10-09', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd11-7bd9-afe0-2e8c5372dedd', '2026-10-10', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7db8-aec5-0a3818ec3319', '2026-10-11', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-77e6-85f3-dcb4cc9f3e66', '2026-10-12', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7206-b5bd-861baf4a82c1', '2026-10-13', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7076-8ae5-d3f9512a062f', '2026-10-14', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-756b-b1c6-d844930177f6', '2026-10-15', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7a8e-9f24-e8b8b7f7e2ab', '2026-10-16', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7c50-b20e-dfa9f8f4214c', '2026-10-17', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-73ec-84a1-dd80e7b3cb87', '2026-10-18', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-71e2-99f7-9f4acf77816c', '2026-10-19', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-72a4-94e7-c8aaaf394c2b', '2026-10-20', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7518-9dc1-726361e03cc5', '2026-10-21', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-73c3-b298-f104d96a1f5b', '2026-10-22', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7fd8-83ef-95e223a46a9f', '2026-10-23', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7b0a-a339-e550baf42a23', '2026-10-24', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-79fa-a0eb-5178b1458b00', '2026-10-25', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7e46-9a4c-8150ac7ec4c1', '2026-10-26', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7d74-afce-74a86c451671', '2026-10-27', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-780e-8dfb-b3b4e004ec7c', '2026-10-28', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-70d9-9e1b-0b71f342b5ab', '2026-10-29', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7ac9-86c6-a664c8311058', '2026-10-30', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7f57-9da8-06695bff377d', '2026-10-31', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-756a-88df-15829fbdc3fe', '2026-11-01', 7, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7409-8b32-bec6e93118b5', '2026-11-02', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-77d9-bd05-e03d2bd5d197', '2026-11-03', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7dfc-b688-d89d7a0ca575', '2026-11-04', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7b39-9d5b-49617aa54bcd', '2026-11-05', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-75cc-95a4-62a773c75ead', '2026-11-06', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7e03-ab1c-d6903a98510a', '2026-11-07', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd12-7bdc-b290-b5e8cb1134e1', '2026-11-08', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7f38-a5f7-36b597152620', '2026-11-09', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-72ed-b84f-4cd2f365a7dc', '2026-11-10', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-730e-975f-3a9d896e1b15', '2026-11-11', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-74fc-84fd-2d78566d6c5d', '2026-11-12', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-70a0-add8-05016b727d5f', '2026-11-13', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-74c3-978d-a93dec04eb9a', '2026-11-14', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7233-a45c-d72c8355dc86', '2026-11-15', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7724-8d5f-1d30f943ae49', '2026-11-16', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7676-8aa0-2a2fdb44e5ed', '2026-11-17', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7066-a009-4a7dc287beb7', '2026-11-18', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7abb-acb7-2a19944a2895', '2026-11-19', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7aea-ac1c-ef1b3f27ab7e', '2026-11-20', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-78a7-ab33-520aee9d8746', '2026-11-21', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7b20-aed7-77da4ea913f1', '2026-11-22', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-70cb-94f9-e990778173e3', '2026-11-23', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7166-a12d-3812d17761fa', '2026-11-24', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-78c7-9ff7-c81c3d961d66', '2026-11-25', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-772a-bdb3-1d3e0438e14f', '2026-11-26', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7b4b-8dc8-1ce7917f1afa', '2026-11-27', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7710-9787-a66f61d1e5c8', '2026-11-28', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7ab8-ba47-b9d145a8db1c', '2026-11-29', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7c7f-9793-9b16e81337e1', '2026-11-30', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7fbf-b402-6cdf20ce381e', '2026-12-01', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7f05-939f-9a4b540d47af', '2026-12-02', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7273-8025-5d0471de8c37', '2026-12-03', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-704c-a71d-f82e831d873c', '2026-12-04', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7b75-b798-41ff9231f333', '2026-12-05', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-7779-b41a-c76ea5ec8ed5', '2026-12-06', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd13-77ac-9b31-54cf60ab7aca', '2026-12-07', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7e56-bf32-9fc0e6db7a79', '2026-12-08', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7bf9-b815-341747743b01', '2026-12-09', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7708-a0cb-fc8cad75fb5f', '2026-12-10', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7507-aaac-19151ce58fe6', '2026-12-11', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7339-b33b-ad8d843f697d', '2026-12-12', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-759e-a990-3b9118501c10', '2026-12-13', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7cc0-8465-a9ae3ee4f708', '2026-12-14', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7c9c-8f63-95835ee5d441', '2026-12-15', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7ab4-a2d0-0c9e73aa73e9', '2026-12-16', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7ecb-899d-1abe340e7f06', '2026-12-17', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7315-9aa8-4f96e59db953', '2026-12-18', 5, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7a5e-9930-7f82dbeba483', '2026-12-19', 6, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-702f-9a53-44389e4a0795', '2026-12-20', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7cfa-9b50-76b565eff307', '2026-12-21', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-73ec-ba49-883882f28c39', '2026-12-22', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7a14-aa36-a9585b3977ad', '2026-12-23', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-75af-af33-b3b910719141', '2026-12-24', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-7a2b-98c4-98cb6a8e5be8', '2026-12-25', 5, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd14-76b7-b26e-bb0e601f832c', '2026-12-26', 6, '019406fb-e4dc-7946-bdef-3a9563e31b0b', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd15-730a-8f2f-d25e9db7380d', '2026-12-27', 7, '019406fb-eb13-7408-b386-df93d83b5fb5', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd15-7737-b6b2-d196234e2ff0', '2026-12-28', 1, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd15-720a-b380-78438e913d57', '2026-12-29', 2, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd15-70d1-b87e-ba60c93e88f3', '2026-12-30', 3, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');
INSERT INTO calendar (id, day, day_of_week, day_type_did, country_did) VALUES ('0196e466-cd15-7e3e-b506-a6c000fc1c10', '2026-12-31', 4, '019406fb-f114-7e66-933c-cc1bfd852569', '019406fa-d0ab-74cf-9334-c56ea0357188');

commit;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
-- --------------------------------------------------------
-- Hoszt:                        127.0.0.1
-- Szerver verzió:               PostgreSQL 16.6 (Debian 16.6-1.pgdg110+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
-- Szerver OS:                   
-- HeidiSQL Verzió:              12.8.0.6908
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES  */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Tábla adatainak mentése company: 36 rows
/*!40000 ALTER TABLE "company" DISABLE KEYS */;
INSERT INTO company (id, short_name, name, company_form_did, group_code, code, tax_number, eu_tax_number, country_did, zip_code, settlement, street_house, inv_country_did, inv_zip_code, inv_settlement, inv_street_house, mail_country_did, mail_zip_code, mail_settlement, mail_street_house, margin, hourly_rate, distance_fee, departure_fee, note, phone, email) VALUES ('01940841-da54-7dee-a346-b2610943e988', 'Exclusive Best Change Zrt.', 'Exclusive Best Change Zrt.', '019406f9-f9a8-7cb4-a90d-5a41a7ec13e2', null, null, null, null, '019406fa-d0ab-74cf-9334-c56ea0357188', '7621', 'Pécs', 'Citrom u. 2-6.', '019406fa-d0ab-74cf-9334-c56ea0357188', '7621', 'Pécs', 'Citrom u. 2-6.', '019406fa-d0ab-74cf-9334-c56ea0357188', '7621', 'Pécs', 'Citrom u. 2-6.', 20, 1234, 190, 8000, null, '+36(70)333-4444', 'info@exclusivebest.hu');
/*!40000 ALTER TABLE "company" ENABLE KEYS */;


-- Tábla adatainak mentése role: 6 rows
/*!40000 ALTER TABLE "role" DISABLE KEYS */;
INSERT INTO role (id, name, description, searchkey) VALUES ('0197778f-36de-7998-9373-2f61c81a5626', 'Pénztáros', 'Pénztáros', 'cashier');
INSERT INTO role (id, name, description, searchkey) VALUES ('01978029-ad37-7d02-ba20-eac5b7e5ab65', 'Értéktáros', 'Értéktáros', 'depository');
INSERT INTO role (id, name, description, searchkey) VALUES ('0197802a-6c6a-7baa-9167-ee8bae171f2d', 'Árfolyam-kezelő', 'Árfolyam-kezelő', 'exchangeRate');
INSERT INTO role (id, name, description, searchkey) VALUES ('0197802a-ece8-7102-9bc0-2ac82b88fb8a', 'Adminisztrátor', 'Adminisztrátor', 'admin');
INSERT INTO role (id, name, description, searchkey) VALUES ('0197802b-60dc-78f8-b89d-e7e1b3143215', 'Vezető adminisztrátor', 'Vezető adminisztrátor', 'superAdmin');
INSERT INTO role (id, name, description, searchkey) VALUES ('0197802b-bff8-7285-bfef-cc468c81363f', 'PuzzleSoft', 'PuzzleSoft', 'puzzle');
INSERT INTO role (id, name, description, searchkey) VALUES ('0197802d-dd9f-7061-bf31-6740365dc760', 'Jogtalan', 'Jogtalan', 'none');

/*!40000 ALTER TABLE "role" ENABLE KEYS */;

-- Tábla adatainak mentése ruser: 2 rows
/*!40000 ALTER TABLE "ruser" DISABLE KEYS */;
INSERT INTO "ruser" ("id", "user_name", "worker_id", "partner_id", "role_id", "last_name", "first_name", "password_hash", "email", "user_enabled", "must_change_pwd") VALUES
	('01940842-7557-74da-a7c7-ea8f013a9156', 'cashier', NULL, NULL, '0197778f-36de-7998-9373-2f61c81a5626', 'Pénztáros', 'István', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
	('01940842-7557-74da-a7c7-ea8f013a9166', 'depository', NULL, NULL, '01978029-ad37-7d02-ba20-eac5b7e5ab65', 'Értéktáros', 'István', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
	('01940842-7557-74da-a7c7-ea8f013a9176', 'exchangerate', NULL, NULL, '0197802a-6c6a-7baa-9167-ee8bae171f2d', 'Árfolyam-kezelő', 'István', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
	('01940842-7557-74da-a7c7-ea8f013a9186', 'admin', NULL, NULL, '0197802a-ece8-7102-9bc0-2ac82b88fb8a', 'Adminisztrátor', 'István', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
	('01940842-7557-74da-a7c7-ea8f013a9196', 'superadmin', NULL, NULL, '0197802b-60dc-78f8-b89d-e7e1b3143215', 'Vezető adminisztrátor', 'István', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
	('01940842-81d7-7bc0-ad94-d519da0d29a8', 'puzzle', '01944f6e-c54e-7d4d-8be8-ad70ec9c2c6d', NULL, '0197802b-bff8-7285-bfef-cc468c81363f', 'PuzzleSoft', 'User', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false),
        ('01940842-81d7-7bc0-ad94-d519da0d29b8', 'none', NULL, NULL, '0197802d-dd9f-7061-bf31-6740365dc760', 'Jogtalan', 'User', '763a1aa9de60a89bf661b84a71e16622', 'borbelytamas.hu@gmail.com', true, false);
/*!40000 ALTER TABLE "ruser" ENABLE KEYS */;

INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('018f3eda-c701-790a-8681-82a9e6ba94c7', 'HUF', 'Magyar forint', 'Ft', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 'EUR', 'Euro', '€', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 'USD', 'Amerikai dollár', '$', true, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000001', 'GBP', 'Angol font', '£', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000002', 'CHF', 'Svájci frank', 'CHF', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000003', 'AUD', 'Ausztrál dollár', 'A$', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000004', 'CAD', 'Kanadai dollár', 'C$', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000005', 'DKK', 'Dán korona', 'kr.', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000006', 'JPY', 'Japán jen', '¥', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000007', 'NOK', 'Norvég korona', 'kr', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000008', 'SEK', 'Svéd korona', 'kr', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000009', 'CZK', 'Cseh korona', 'Kč', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000010', 'HRK', 'Horvát kuna', 'kn', false, false, '01840560-d523-7e1f-a420-98765c429a0b');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000011', 'PLN', 'Lengyel złoty', 'zł', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000012', 'RON', 'Román lej', 'L', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000013', 'RSD', 'Szerb dinár', 'дин.', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000014', 'BGN', 'Bolgár leva', 'лв.', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000015', 'ILS', 'Izraeli új sékel', '₪', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000016', 'UAH', 'Ukrán hrivnya', '₴', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000017', 'RUB', 'Orosz rubel', '₽', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000018', 'TRY', 'Török líra', '₺', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000019', 'CNY', 'Kínai jüan', '¥', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000020', 'BAM', 'Bosnyák konvertibilis márka', 'KM', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000021', 'THB', 'Thai bát', '฿', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000022', 'BRL', 'Brazil reál', 'R$', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000023', 'MXN', 'Mexikói peso', '$', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');
INSERT INTO currency (id, code, name, symbol, is_base, is_active, currency_status_did) VALUES ('0190b0d2-5a7a-7f20-a123-000000000024', 'NZD', 'Új-zélandi dollár', 'NZ$', false, true, '01840560-a617-7c63-9e46-aff48f2b0724');

INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e72-780b-b310-025564155cda', '018f3eda-c701-790a-8681-82a9e6ba94c7', 5, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e75-7067-a2a4-5673af364831', '018f3eda-c701-790a-8681-82a9e6ba94c7', 10, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e75-7ffd-8f6e-6430a9ab9d7c', '018f3eda-c701-790a-8681-82a9e6ba94c7', 20, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e75-71be-8494-361adb8d4365', '018f3eda-c701-790a-8681-82a9e6ba94c7', 50, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e75-7999-ac46-bcbf467b6693', '018f3eda-c701-790a-8681-82a9e6ba94c7', 100, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2e75-736a-a1c0-64d7665d058e', '018f3eda-c701-790a-8681-82a9e6ba94c7', 200, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-7fe3-93eb-761deb6058a5', '018f3eda-c701-790a-8681-82a9e6ba94c7', 500, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-7406-bc9a-3ae7bd99c8ba', '018f3eda-c701-790a-8681-82a9e6ba94c7', 1000, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-7979-bbfc-e45421e22de6', '018f3eda-c701-790a-8681-82a9e6ba94c7', 2000, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-70b9-8f5c-b2914b9a5ece', '018f3eda-c701-790a-8681-82a9e6ba94c7', 5000, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-7f12-be03-e99a2f74356a', '018f3eda-c701-790a-8681-82a9e6ba94c7', 10000, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ea2-7267-b1b9-1802f3687e4d', '018f3eda-c701-790a-8681-82a9e6ba94c7', 20000, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7fb3-b1da-e91026afe72a', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7bb0-8e56-acc261eb2173', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.02, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7b5b-a921-02c63e7d784b', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.05, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7ed0-a5fd-a05155f7bcf3', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-77f9-a6f0-fd354df9f0c6', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-782e-bb14-3786c8456d1e', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0.5, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7319-8798-6ffafa15dee0', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 1, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ebb-7e55-823c-2cef9032bb44', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 2, true, true, 80, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ece-70c4-9c4b-35f0fed22f69', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 5, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ecf-719f-a726-71df85a867a2', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 10, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ecf-7ae6-b0a0-618e84a19aaa', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 20, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ecf-7878-ac5d-ebeaaa771776', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 50, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ecf-7a5e-a526-f1cad93daa93', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 100, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ecf-730c-b33d-da24d17886ce', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 200, false, true, 140, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-7581-97f9-a55edbca532d', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-7e99-bd22-5cf62b542a6d', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 0.05, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-70ee-ad44-ee779ec8ebf9', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 0.1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-7fd1-93ec-f96978460e7c', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 0.25, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-7630-8009-f5d44aa9219a', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 0.5, true, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2eeb-71a3-b3e7-7eb2db9eb695', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 1, true, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-7719-bd90-94449cce8edf', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 1, false, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-71eb-988b-270cc21c3841', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 2, false, true, 80, '01967c22-c345-736a-9408-5cd3e99dc222');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-78ed-8ae5-a50e04356f7c', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 5, false, true, 90, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-70c4-8fef-cc05f5388749', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 10, false, true, 100, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-7318-8dd7-3f84282020b7', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 20, false, true, 110, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-7578-b05e-0ad2b9bc11c7', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 50, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-723e-a2e7-bece9eac281d', '0190b0d2-5a7a-7f20-a123-000000000001', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-7747-a6ff-78f771030efb', '0190b0d2-5a7a-7f20-a123-000000000001', 0.02, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-72c6-9b4b-d0242d3c4fa5', '0190b0d2-5a7a-7f20-a123-000000000001', 0.05, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-7350-9b7c-25bc0c275847', '0190b0d2-5a7a-7f20-a123-000000000001', 0.1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-7e93-90c7-c42c5fa20cbd', '0190b0d2-5a7a-7f20-a123-000000000001', 0.2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-7147-85e4-752476b459f0', '0190b0d2-5a7a-7f20-a123-000000000001', 0.5, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-7504-a542-8a20ee3757c9', '0190b0d2-5a7a-7f20-a123-000000000001', 1, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f32-74b1-bf0b-b0e22b3f434c', '0190b0d2-5a7a-7f20-a123-000000000001', 2, true, true, 80, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f40-7552-b9c3-10da76826e7a', '0190b0d2-5a7a-7f20-a123-000000000001', 5, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f40-706c-a7fa-e45d196005ea', '0190b0d2-5a7a-7f20-a123-000000000001', 10, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f40-7691-8e18-bf66d1cdd5e8', '0190b0d2-5a7a-7f20-a123-000000000001', 20, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f40-72c6-b16e-e87c157a0fdf', '0190b0d2-5a7a-7f20-a123-000000000001', 50, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-7189-a6f5-bfd961cdc277', '0190b0d2-5a7a-7f20-a123-000000000002', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-783a-a124-554257725bea', '0190b0d2-5a7a-7f20-a123-000000000002', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-7e1e-95ed-13f340fd313b', '0190b0d2-5a7a-7f20-a123-000000000002', 0.2, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-786c-8474-e5cd4922b862', '0190b0d2-5a7a-7f20-a123-000000000002', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-79a5-a4ec-c134c7c3e1e2', '0190b0d2-5a7a-7f20-a123-000000000002', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-714b-9467-874341f67510', '0190b0d2-5a7a-7f20-a123-000000000002', 2, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f4e-71a1-8c16-00223704c785', '0190b0d2-5a7a-7f20-a123-000000000002', 5, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-77a4-ae22-c3bfb4394095', '0190b0d2-5a7a-7f20-a123-000000000002', 10, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-79f7-9e48-0cda6330f402', '0190b0d2-5a7a-7f20-a123-000000000002', 20, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-7cb1-807d-1b3e10c13352', '0190b0d2-5a7a-7f20-a123-000000000002', 50, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-7476-ac42-719f9cc258f7', '0190b0d2-5a7a-7f20-a123-000000000002', 100, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-7e18-a219-05dd3695f4f5', '0190b0d2-5a7a-7f20-a123-000000000002', 200, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f6c-7e3f-b6a5-608e80b47ea7', '0190b0d2-5a7a-7f20-a123-000000000002', 1000, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-7601-a4ce-416a9d12b18f', '0190b0d2-5a7a-7f20-a123-000000000003', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-7574-ac67-a533211dd16b', '0190b0d2-5a7a-7f20-a123-000000000003', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-7707-91c9-64c398f1ddd4', '0190b0d2-5a7a-7f20-a123-000000000003', 0.2, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-73c9-8f64-ce2b6cabafd8', '0190b0d2-5a7a-7f20-a123-000000000003', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-79d3-a19f-261a09539835', '0190b0d2-5a7a-7f20-a123-000000000003', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f7e-7ca4-a931-c3e195f0123a', '0190b0d2-5a7a-7f20-a123-000000000003', 2, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f8e-7457-8ee3-3b6a391848c2', '0190b0d2-5a7a-7f20-a123-000000000003', 5, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f8e-762d-b8a3-288681293d20', '0190b0d2-5a7a-7f20-a123-000000000003', 10, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f8e-7cd8-9f5a-6ad570f11943', '0190b0d2-5a7a-7f20-a123-000000000003', 20, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f8e-70b9-a865-78e02d54f8af', '0190b0d2-5a7a-7f20-a123-000000000003', 50, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f8e-7694-8fc5-4edff102d967', '0190b0d2-5a7a-7f20-a123-000000000003', 100, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fae-71a7-b535-fbe6eee34908', '0190b0d2-5a7a-7f20-a123-000000000004', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fae-7700-a654-8c5dea1dedd1', '0190b0d2-5a7a-7f20-a123-000000000004', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fae-7525-9e05-03f1fa14622c', '0190b0d2-5a7a-7f20-a123-000000000004', 0.25, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fae-7dda-ae6e-cdcc9e892789', '0190b0d2-5a7a-7f20-a123-000000000004', 1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fae-7419-b552-5497887b3099', '0190b0d2-5a7a-7f20-a123-000000000004', 2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fbd-736b-a7cb-10926bc50216', '0190b0d2-5a7a-7f20-a123-000000000004', 5, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fbd-7c59-b30c-90d1d61100b4', '0190b0d2-5a7a-7f20-a123-000000000004', 10, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fbd-775d-be69-c980a9ffb82e', '0190b0d2-5a7a-7f20-a123-000000000004', 20, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fbd-7bc1-9aa7-fa790b97a5fb', '0190b0d2-5a7a-7f20-a123-000000000004', 50, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fbd-7cab-bcc6-7f3e532d7985', '0190b0d2-5a7a-7f20-a123-000000000004', 100, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcd-7e5f-ace3-e4bac63a89fb', '0190b0d2-5a7a-7f20-a123-000000000005', 0.5, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcd-7781-9347-0817ab2a2e7c', '0190b0d2-5a7a-7f20-a123-000000000005', 1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcd-7c3f-bba1-659f2a5ce530', '0190b0d2-5a7a-7f20-a123-000000000005', 2, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcd-7faa-9138-f25c9bb89840', '0190b0d2-5a7a-7f20-a123-000000000005', 5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcf-772a-9599-5d28c6adebed', '0190b0d2-5a7a-7f20-a123-000000000005', 10, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fcf-7336-915d-101bb46bec78', '0190b0d2-5a7a-7f20-a123-000000000005', 20, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fe9-7029-95e0-58f9bbfb8872', '0190b0d2-5a7a-7f20-a123-000000000005', 50, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fe9-775e-9405-1827d33e35a5', '0190b0d2-5a7a-7f20-a123-000000000005', 100, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fe9-760a-9ad5-34ee0c0ea27d', '0190b0d2-5a7a-7f20-a123-000000000005', 200, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fe9-7487-bae7-83bea9dc5b70', '0190b0d2-5a7a-7f20-a123-000000000005', 500, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2fe9-7932-86a2-86e0987fb4b6', '0190b0d2-5a7a-7f20-a123-000000000005', 1000, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-7189-a030-6f9564e9bded', '0190b0d2-5a7a-7f20-a123-000000000006', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-79e0-8eac-b86e2c54cef2', '0190b0d2-5a7a-7f20-a123-000000000006', 5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-7bb8-8c6e-a1eb2dfe0025', '0190b0d2-5a7a-7f20-a123-000000000006', 10, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-717e-b4f5-9914abf25f88', '0190b0d2-5a7a-7f20-a123-000000000006', 50, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-7d5a-92cd-5401073d7ca3', '0190b0d2-5a7a-7f20-a123-000000000006', 100, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2ff7-7b2e-ade7-30a3cc7ea15e', '0190b0d2-5a7a-7f20-a123-000000000006', 500, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3009-721d-841f-f2f57646b23f', '0190b0d2-5a7a-7f20-a123-000000000006', 1000, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3009-7e5c-983d-612a9298f6a9', '0190b0d2-5a7a-7f20-a123-000000000006', 2000, false, true, 80, '01967c22-c345-736a-9408-5cd3e99dc222');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3009-7acf-bf8d-ec325c006f92', '0190b0d2-5a7a-7f20-a123-000000000006', 5000, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3009-735b-8af4-af78437ec3c1', '0190b0d2-5a7a-7f20-a123-000000000006', 10000, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-301f-781f-a633-1b4397523b88', '0190b0d2-5a7a-7f20-a123-000000000007', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-301f-79ed-9334-8edb201e22c6', '0190b0d2-5a7a-7f20-a123-000000000007', 5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-301f-7e7c-ab93-2f398dd0c221', '0190b0d2-5a7a-7f20-a123-000000000007', 10, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-301f-77ab-8771-f977e717bd79', '0190b0d2-5a7a-7f20-a123-000000000007', 20, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-302e-73fb-932e-ad8c0817f5fb', '0190b0d2-5a7a-7f20-a123-000000000007', 50, false, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-302e-7c5a-90a8-3ddea81f5de9', '0190b0d2-5a7a-7f20-a123-000000000007', 100, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-302e-7fa7-90fa-fc37f45a3b86', '0190b0d2-5a7a-7f20-a123-000000000007', 200, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-302e-74da-99c4-718c33d75d70', '0190b0d2-5a7a-7f20-a123-000000000007', 500, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-302e-7321-bba1-5a7df6ab00b6', '0190b0d2-5a7a-7f20-a123-000000000007', 1000, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-303b-727a-a246-0d328b310705', '0190b0d2-5a7a-7f20-a123-000000000008', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-303b-71a1-96ca-d8f1a5799792', '0190b0d2-5a7a-7f20-a123-000000000008', 2, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-303b-75b6-8c67-f64b5bab5c3c', '0190b0d2-5a7a-7f20-a123-000000000008', 5, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-303b-79fa-8823-998b4b197995', '0190b0d2-5a7a-7f20-a123-000000000008', 10, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-755d-b4a1-e0ddf54a2918', '0190b0d2-5a7a-7f20-a123-000000000008', 20, false, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-7587-bfd1-5763c354388c', '0190b0d2-5a7a-7f20-a123-000000000008', 50, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-77e6-8001-fd17ba50439d', '0190b0d2-5a7a-7f20-a123-000000000008', 100, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-7f69-b86e-10b58d55055f', '0190b0d2-5a7a-7f20-a123-000000000008', 200, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-7f3c-88fa-003e7256b903', '0190b0d2-5a7a-7f20-a123-000000000008', 500, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-305c-708e-b38e-1b173e33e68a', '0190b0d2-5a7a-7f20-a123-000000000008', 1000, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-7483-a31f-55261acc5d1e', '0190b0d2-5a7a-7f20-a123-000000000009', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-74d2-a853-444ef6cdc9b2', '0190b0d2-5a7a-7f20-a123-000000000009', 2, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-7529-9de9-6540cd43a9a9', '0190b0d2-5a7a-7f20-a123-000000000009', 5, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-7bce-9316-0b3a94f68ccd', '0190b0d2-5a7a-7f20-a123-000000000009', 10, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-773e-8ed3-45fbc2edb62b', '0190b0d2-5a7a-7f20-a123-000000000009', 20, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-306c-704f-866e-a8155240ec97', '0190b0d2-5a7a-7f20-a123-000000000009', 50, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-725a-bbfb-1da202a45a41', '0190b0d2-5a7a-7f20-a123-000000000009', 100, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-7218-afcb-a238d91f0d57', '0190b0d2-5a7a-7f20-a123-000000000009', 200, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-73ca-adfc-8fbc72143fa2', '0190b0d2-5a7a-7f20-a123-000000000009', 500, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-7653-b40c-d33c79d9bc7c', '0190b0d2-5a7a-7f20-a123-000000000009', 1000, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-7107-9769-f1a7b848476d', '0190b0d2-5a7a-7f20-a123-000000000009', 2000, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-307a-7938-8ccd-52daba4552c7', '0190b0d2-5a7a-7f20-a123-000000000009', 5000, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3087-77b3-9391-e00c3e208141', '0190b0d2-5a7a-7f20-a123-000000000010', 0.01, true, false, 10, '01967c22-d456-7d9b-9c77-003175234333');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3087-76ff-8331-8a9b3caf28c3', '0190b0d2-5a7a-7f20-a123-000000000010', 1, true, false, 70, '01967c22-d456-7d9b-9c77-003175234333');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30a2-7c17-af80-0562a1d7729b', '0190b0d2-5a7a-7f20-a123-000000000010', 10, false, false, 80, '01967c22-d456-7d9b-9c77-003175234333');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-725d-81c6-e8dbea65a4af', '0190b0d2-5a7a-7f20-a123-000000000011', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7443-a275-fcfe598709f2', '0190b0d2-5a7a-7f20-a123-000000000011', 0.02, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7a8b-bfa2-b5e197e41eaf', '0190b0d2-5a7a-7f20-a123-000000000011', 0.05, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7d22-ba54-0f411ad20c3e', '0190b0d2-5a7a-7f20-a123-000000000011', 0.1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7d3d-a53d-edb3acc50b6f', '0190b0d2-5a7a-7f20-a123-000000000011', 0.2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7421-89f8-5107c069c83b', '0190b0d2-5a7a-7f20-a123-000000000011', 0.5, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-718c-a0af-878a883d8070', '0190b0d2-5a7a-7f20-a123-000000000011', 1, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-7952-9540-6902bf1c8d0d', '0190b0d2-5a7a-7f20-a123-000000000011', 2, true, true, 80, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30b4-76d0-8d9f-79ff997cc8f4', '0190b0d2-5a7a-7f20-a123-000000000011', 5, true, true, 90, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-7718-b0fa-1461be9bd6c6', '0190b0d2-5a7a-7f20-a123-000000000011', 10, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-735c-af71-08d9fdbce0d2', '0190b0d2-5a7a-7f20-a123-000000000011', 20, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-7b64-bbed-279aef051a8b', '0190b0d2-5a7a-7f20-a123-000000000011', 50, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-7f07-a306-45689d74c355', '0190b0d2-5a7a-7f20-a123-000000000011', 100, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-7c6c-b7bf-a9a930962e9c', '0190b0d2-5a7a-7f20-a123-000000000011', 200, false, true, 140, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30d0-7d2c-8192-dac998ef735a', '0190b0d2-5a7a-7f20-a123-000000000011', 500, false, true, 150, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30dd-762a-a106-5e1c64727303', '0190b0d2-5a7a-7f20-a123-000000000012', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30dd-7876-90ad-f0f26d4997aa', '0190b0d2-5a7a-7f20-a123-000000000012', 0.05, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30dd-788f-91e4-b6c5ba19db60', '0190b0d2-5a7a-7f20-a123-000000000012', 0.1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30dd-7c8e-bb3b-7ab4cd923c89', '0190b0d2-5a7a-7f20-a123-000000000012', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-7a64-ae78-48f7746aaaa2', '0190b0d2-5a7a-7f20-a123-000000000012', 1, false, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-7432-8287-439f9ee69762', '0190b0d2-5a7a-7f20-a123-000000000012', 5, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-7652-b922-3c5413a3910f', '0190b0d2-5a7a-7f20-a123-000000000012', 10, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-777e-b106-9df4e65c97b9', '0190b0d2-5a7a-7f20-a123-000000000012', 50, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-7608-b46b-1ad5528976fe', '0190b0d2-5a7a-7f20-a123-000000000012', 100, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-7c2e-8bd9-a796abc38085', '0190b0d2-5a7a-7f20-a123-000000000012', 200, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-30ed-78af-9278-7d9f781caf08', '0190b0d2-5a7a-7f20-a123-000000000012', 500, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-310d-7c1b-af5c-5cd9c4f8b6e5', '0190b0d2-5a7a-7f20-a123-000000000013', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-310d-77a7-81e4-4cd5eefa967d', '0190b0d2-5a7a-7f20-a123-000000000013', 2, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-310d-746f-88c1-acdd95db2f5d', '0190b0d2-5a7a-7f20-a123-000000000013', 5, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-310d-773e-b6d7-fe3865ab23a0', '0190b0d2-5a7a-7f20-a123-000000000013', 10, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-310d-7362-801f-0562b720d92b', '0190b0d2-5a7a-7f20-a123-000000000013', 20, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-7a37-a2c4-195cb7c43506', '0190b0d2-5a7a-7f20-a123-000000000013', 10, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-7878-8672-23e43428c376', '0190b0d2-5a7a-7f20-a123-000000000013', 20, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-762e-9c07-128c4c253ad1', '0190b0d2-5a7a-7f20-a123-000000000013', 50, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-73ff-8709-f3c6750bc7cc', '0190b0d2-5a7a-7f20-a123-000000000013', 100, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-74c1-89cf-5d56ae76e0b5', '0190b0d2-5a7a-7f20-a123-000000000013', 200, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-7acd-b81e-e59faeb10023', '0190b0d2-5a7a-7f20-a123-000000000013', 500, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-75e9-b7f0-82e879836743', '0190b0d2-5a7a-7f20-a123-000000000013', 1000, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-733e-8d3e-ddbf72a2ab77', '0190b0d2-5a7a-7f20-a123-000000000013', 2000, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3120-7702-9ed6-55c3795ba723', '0190b0d2-5a7a-7f20-a123-000000000013', 5000, false, true, 140, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7593-aabc-b7cf68213bfd', '0190b0d2-5a7a-7f20-a123-000000000014', 0.01, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7c39-8ef4-b28f049d984f', '0190b0d2-5a7a-7f20-a123-000000000014', 0.02, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7d76-a5e5-65aed135c403', '0190b0d2-5a7a-7f20-a123-000000000014', 0.05, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7d3b-aef1-0503d44c4529', '0190b0d2-5a7a-7f20-a123-000000000014', 0.1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7d84-91bc-fb9a4e28cbcf', '0190b0d2-5a7a-7f20-a123-000000000014', 0.2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7c13-8ad9-63c1c3157e46', '0190b0d2-5a7a-7f20-a123-000000000014', 0.5, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-7a58-94b8-7e076480f7c7', '0190b0d2-5a7a-7f20-a123-000000000014', 1, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-312f-78a7-8942-7ee5d316fe9c', '0190b0d2-5a7a-7f20-a123-000000000014', 2, true, true, 80, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-314c-78e3-8f2e-7256e5138cc4', '0190b0d2-5a7a-7f20-a123-000000000014', 5, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-314c-760b-8892-f5c5e31be4b9', '0190b0d2-5a7a-7f20-a123-000000000014', 10, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-314c-75c0-b1be-ebebbe77fade', '0190b0d2-5a7a-7f20-a123-000000000014', 20, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-314c-7652-99d8-02972450e69a', '0190b0d2-5a7a-7f20-a123-000000000014', 50, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-314c-7656-8377-d3508cf469ac', '0190b0d2-5a7a-7f20-a123-000000000014', 100, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-7446-9638-baa4194f0bb9', '0190b0d2-5a7a-7f20-a123-000000000015', 0.1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-79a3-8e5c-07d5b27e1c16', '0190b0d2-5a7a-7f20-a123-000000000015', 0.5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-7c87-856c-c6c1b1f52555', '0190b0d2-5a7a-7f20-a123-000000000015', 1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-7fe5-82b9-5c8e7f1e1763', '0190b0d2-5a7a-7f20-a123-000000000015', 2, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-7f50-bd60-3832c2c75a3a', '0190b0d2-5a7a-7f20-a123-000000000015', 5, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-315b-7e90-88c6-20f0b236d065', '0190b0d2-5a7a-7f20-a123-000000000015', 10, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3168-7c37-ace8-34eb2c917116', '0190b0d2-5a7a-7f20-a123-000000000015', 20, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3168-7659-ba13-0966a4c34cab', '0190b0d2-5a7a-7f20-a123-000000000015', 50, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3168-7c82-b14b-b13152a4abf0', '0190b0d2-5a7a-7f20-a123-000000000015', 100, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3168-79f4-a608-005e1982f5c6', '0190b0d2-5a7a-7f20-a123-000000000015', 200, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-7807-aa49-3a04f335382d', '0190b0d2-5a7a-7f20-a123-000000000016', 0.1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-7a0d-9957-d42acbbf98c8', '0190b0d2-5a7a-7f20-a123-000000000016', 0.5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-7525-9763-716c77233757', '0190b0d2-5a7a-7f20-a123-000000000016', 1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-7461-b1ba-b640da2acbfe', '0190b0d2-5a7a-7f20-a123-000000000016', 2, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-7baa-a0e4-8b617462adf0', '0190b0d2-5a7a-7f20-a123-000000000016', 5, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-318a-741a-b215-130c09b7683e', '0190b0d2-5a7a-7f20-a123-000000000016', 10, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-71d9-b835-376bcb6a628c', '0190b0d2-5a7a-7f20-a123-000000000016', 20, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-7f7c-896e-dd8c17b46502', '0190b0d2-5a7a-7f20-a123-000000000016', 50, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-7f19-927b-40590bfe453a', '0190b0d2-5a7a-7f20-a123-000000000016', 100, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-7c22-9910-8cf6fc4dfec5', '0190b0d2-5a7a-7f20-a123-000000000016', 200, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-7133-869f-ba52ac1a373d', '0190b0d2-5a7a-7f20-a123-000000000016', 500, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3199-75fc-a274-c4d8e4e2e427', '0190b0d2-5a7a-7f20-a123-000000000016', 1000, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31a6-7268-8e2e-19b05cd31b7a', '0190b0d2-5a7a-7f20-a123-000000000017', 1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31a6-7402-88f0-572651a5662b', '0190b0d2-5a7a-7f20-a123-000000000017', 2, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31a6-7ff8-b811-5f9c7875be3b', '0190b0d2-5a7a-7f20-a123-000000000017', 5, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31a6-7a6f-a959-d88ff41b48c4', '0190b0d2-5a7a-7f20-a123-000000000017', 10, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-7b66-9510-fa69ce90d9f7', '0190b0d2-5a7a-7f20-a123-000000000017', 50, false, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-7f9a-92f4-e3e2a602a8c3', '0190b0d2-5a7a-7f20-a123-000000000017', 100, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-71b9-9037-34b70732a32d', '0190b0d2-5a7a-7f20-a123-000000000017', 200, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-7547-9b32-e94487eaeb88', '0190b0d2-5a7a-7f20-a123-000000000017', 500, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-767d-a13e-70c0b9c3975f', '0190b0d2-5a7a-7f20-a123-000000000017', 1000, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-7d94-8158-8f7e6d2f2199', '0190b0d2-5a7a-7f20-a123-000000000017', 2000, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31b4-73d6-af8f-ce7a7ed42382', '0190b0d2-5a7a-7f20-a123-000000000017', 5000, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-7c95-8454-2bbd4ba2096d', '0190b0d2-5a7a-7f20-a123-000000000018', 0.01, true, true, 5, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-7311-a81f-c53612a5d788', '0190b0d2-5a7a-7f20-a123-000000000018', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-78ef-a1c2-baeb11f920a7', '0190b0d2-5a7a-7f20-a123-000000000018', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-7957-9db8-34a3a8e514c6', '0190b0d2-5a7a-7f20-a123-000000000018', 0.25, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-7186-9ba3-fd69f9a34754', '0190b0d2-5a7a-7f20-a123-000000000018', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31d4-7a75-98f3-a66b7301f63e', '0190b0d2-5a7a-7f20-a123-000000000018', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-76a2-9b02-c3601514a841', '0190b0d2-5a7a-7f20-a123-000000000018', 5, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-7e32-8b89-76b65be01321', '0190b0d2-5a7a-7f20-a123-000000000018', 10, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-7eb0-b6f5-9eb7c53bc928', '0190b0d2-5a7a-7f20-a123-000000000018', 20, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-7f25-bc5f-d88175fdee6e', '0190b0d2-5a7a-7f20-a123-000000000018', 50, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-77e3-b745-444810f58c36', '0190b0d2-5a7a-7f20-a123-000000000018', 100, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31e1-7284-8d5a-6393f1791ddc', '0190b0d2-5a7a-7f20-a123-000000000018', 200, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31ef-7897-9fb6-d66531894979', '0190b0d2-5a7a-7f20-a123-000000000019', 0.1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31ef-7af6-bbe6-12cf81690f9f', '0190b0d2-5a7a-7f20-a123-000000000019', 0.5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-31ef-73a9-8928-187ed2536114', '0190b0d2-5a7a-7f20-a123-000000000019', 1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7888-ab62-9052b9c32e13', '0190b0d2-5a7a-7f20-a123-000000000019', 0.1, false, true, 40, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-76ce-a6d0-3c0668264c76', '0190b0d2-5a7a-7f20-a123-000000000019', 0.5, false, true, 50, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7171-a817-4f321207a0c4', '0190b0d2-5a7a-7f20-a123-000000000019', 1, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7082-82d9-ff6b4a0ab889', '0190b0d2-5a7a-7f20-a123-000000000019', 5, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7bf6-8fb0-4193e1e319b9', '0190b0d2-5a7a-7f20-a123-000000000019', 10, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7143-92d2-d7550522c49e', '0190b0d2-5a7a-7f20-a123-000000000019', 20, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-7279-af83-67e0b83d1c94', '0190b0d2-5a7a-7f20-a123-000000000019', 50, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3200-78a2-bcee-386f9fb2854e', '0190b0d2-5a7a-7f20-a123-000000000019', 100, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-7f9d-b5a2-c5cfc45cc20d', '0190b0d2-5a7a-7f20-a123-000000000020', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-78be-b3c9-70cf53d0a7a5', '0190b0d2-5a7a-7f20-a123-000000000020', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-71fe-82e9-89d49fd345c3', '0190b0d2-5a7a-7f20-a123-000000000020', 0.2, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-7df7-9a89-6df5d165a13f', '0190b0d2-5a7a-7f20-a123-000000000020', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-7cea-b932-8a7179edb8d2', '0190b0d2-5a7a-7f20-a123-000000000020', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-7076-8946-849041dc5d27', '0190b0d2-5a7a-7f20-a123-000000000020', 2, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-321b-7eac-9f65-4c80a041fae3', '0190b0d2-5a7a-7f20-a123-000000000020', 5, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3229-753c-aabf-bf5261717cc2', '0190b0d2-5a7a-7f20-a123-000000000020', 10, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3229-79c9-b16d-3b1b873ba857', '0190b0d2-5a7a-7f20-a123-000000000020', 20, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3229-778d-8d4b-90a7ba637574', '0190b0d2-5a7a-7f20-a123-000000000020', 50, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3229-7310-a380-a8c0b7455829', '0190b0d2-5a7a-7f20-a123-000000000020', 100, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3229-7c54-bb9d-a29bea16ab49', '0190b0d2-5a7a-7f20-a123-000000000020', 200, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3237-7f32-a3b5-3df52146f887', '0190b0d2-5a7a-7f20-a123-000000000021', 0.25, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3237-7ca8-8801-2e2209f56abe', '0190b0d2-5a7a-7f20-a123-000000000021', 0.5, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3237-71d1-aae0-731761d7de0b', '0190b0d2-5a7a-7f20-a123-000000000021', 1, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3237-7682-820e-1a35b0e8d4c1', '0190b0d2-5a7a-7f20-a123-000000000021', 2, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3238-72dc-9bcc-fa69022aa5ad', '0190b0d2-5a7a-7f20-a123-000000000021', 5, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3238-778f-b9d5-0f2ec4aefe2e', '0190b0d2-5a7a-7f20-a123-000000000021', 10, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3259-7561-9a62-54cbbb0ac9b5', '0190b0d2-5a7a-7f20-a123-000000000021', 20, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3259-7674-bfc4-9c77be4bc0e0', '0190b0d2-5a7a-7f20-a123-000000000021', 50, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3259-7546-8581-905c3b8a6b12', '0190b0d2-5a7a-7f20-a123-000000000021', 100, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3259-7d89-9b0d-f883306c3217', '0190b0d2-5a7a-7f20-a123-000000000021', 500, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3259-734f-9eac-5fa634649317', '0190b0d2-5a7a-7f20-a123-000000000021', 1000, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-326c-7be4-86c0-4b7636d1af30', '0190b0d2-5a7a-7f20-a123-000000000022', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-326c-73b2-81bc-79646cd6b58f', '0190b0d2-5a7a-7f20-a123-000000000022', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-326c-7494-a1f5-db7ea90b3467', '0190b0d2-5a7a-7f20-a123-000000000022', 0.25, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-326c-7bb6-9051-1c5f155cb215', '0190b0d2-5a7a-7f20-a123-000000000022', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-326c-7c38-b894-c3b1800d8c6f', '0190b0d2-5a7a-7f20-a123-000000000022', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-7a72-a186-4b14bfe8dff8', '0190b0d2-5a7a-7f20-a123-000000000022', 2, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-767b-bbb4-dc98ace22029', '0190b0d2-5a7a-7f20-a123-000000000022', 5, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-758f-9522-d8d3eabb10c2', '0190b0d2-5a7a-7f20-a123-000000000022', 10, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-73ae-8cde-70e4f6f932d4', '0190b0d2-5a7a-7f20-a123-000000000022', 20, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-7754-9271-72e8ed693c1b', '0190b0d2-5a7a-7f20-a123-000000000022', 50, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-71d6-acdf-e0df790f50e5', '0190b0d2-5a7a-7f20-a123-000000000022', 100, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-327b-7b03-ac03-be51601c0923', '0190b0d2-5a7a-7f20-a123-000000000022', 200, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-7ac5-8a85-3dcdff7adfed', '0190b0d2-5a7a-7f20-a123-000000000023', 0.05, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-7a3b-8826-7116e812b00c', '0190b0d2-5a7a-7f20-a123-000000000023', 0.1, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-7113-8c37-255a7666ffa4', '0190b0d2-5a7a-7f20-a123-000000000023', 0.2, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-7164-a538-c50a5a1afab3', '0190b0d2-5a7a-7f20-a123-000000000023', 0.5, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-7848-ada0-5e33646ebcc1', '0190b0d2-5a7a-7f20-a123-000000000023', 1, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-777b-8f44-9136824391cc', '0190b0d2-5a7a-7f20-a123-000000000023', 2, true, true, 60, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-71f9-82e8-47b5c96d9dad', '0190b0d2-5a7a-7f20-a123-000000000023', 5, true, true, 70, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3295-737c-aece-1f7c809dda3f', '0190b0d2-5a7a-7f20-a123-000000000023', 10, true, true, 80, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-3296-7f50-bea2-eed4aba1feb9', '0190b0d2-5a7a-7f20-a123-000000000023', 20, true, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-7f98-9852-21da75269636', '0190b0d2-5a7a-7f20-a123-000000000023', 20, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-7afc-8a67-6f25b9629f69', '0190b0d2-5a7a-7f20-a123-000000000023', 50, false, true, 110, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-7ca9-b72a-c1e78d90dbf6', '0190b0d2-5a7a-7f20-a123-000000000023', 100, false, true, 120, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-78d4-8695-dc36c5245deb', '0190b0d2-5a7a-7f20-a123-000000000023', 200, false, true, 130, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-756c-b2e3-fcd5a35a23e6', '0190b0d2-5a7a-7f20-a123-000000000023', 500, false, true, 140, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32a8-737f-9045-b773396fe7d6', '0190b0d2-5a7a-7f20-a123-000000000023', 1000, false, true, 150, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32b6-7520-b15c-c556f00b5776', '0190b0d2-5a7a-7f20-a123-000000000024', 0.1, true, true, 10, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32b6-749f-8123-7888b9ef4959', '0190b0d2-5a7a-7f20-a123-000000000024', 0.2, true, true, 20, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32b6-7e56-a8c5-37224ba80201', '0190b0d2-5a7a-7f20-a123-000000000024', 0.5, true, true, 30, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32b6-7459-bec0-9de76f8f359b', '0190b0d2-5a7a-7f20-a123-000000000024', 1, true, true, 40, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32b6-7aa0-ac9a-cd192e2653de', '0190b0d2-5a7a-7f20-a123-000000000024', 2, true, true, 50, '01967c22-a123-7a22-b345-01ac432de000');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32d1-71d6-a25e-25e949a6e75b', '0190b0d2-5a7a-7f20-a123-000000000024', 5, false, true, 60, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32d1-79be-88f7-d438585d75e8', '0190b0d2-5a7a-7f20-a123-000000000024', 10, false, true, 70, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32d1-7d3f-a405-41168b0b0cf8', '0190b0d2-5a7a-7f20-a123-000000000024', 20, false, true, 80, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32d1-728c-8c05-d62e66a3d533', '0190b0d2-5a7a-7f20-a123-000000000024', 50, false, true, 90, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-32d1-705a-b810-011825e8498b', '0190b0d2-5a7a-7f20-a123-000000000024', 100, false, true, 100, '01967c22-b234-7b33-c456-12bd543ef111');
INSERT INTO currency_denomination (id, currency_id, denomination, is_coin, is_active, sorting_order, availability_did) VALUES ('019755b6-2f00-70a7-ba2c-3e5319edf8fd', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', 100, false, false, 130, '01967c22-b234-7b33-c456-12bd543ef111');


INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('f1b0d9e0-1c7f-4b9f-8c3a-1e7a6d0b4f01', 'panel_home_dashboard_home', 'home', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('a2c1e8f1-2d80-4c0a-9d4b-2f8b7e1c5a02', 'panel_valuta_vetele_figdef_worker_ext0', 'Valuta vétele', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('b3d2f7a2-3e91-4d1b-ae5c-3a9c8f2d6b03', 'panel_valuta_eladasa_figdef_worker_ext1', 'Valuta eladása', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('c4e3a6b3-4fa2-4e2c-bf6d-4ba09a3e7c04', 'panel_valuta_konverzio_figdef_worker_ext1x', 'Valuta konverzió', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('d5f4b5c4-50b3-4f3d-ca7e-5cb1aa4f8d05', 'panel_kassza_nyitasa_figdef_worker_ext2', 'Kassza nyitása', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('e605c4d5-61c4-404e-db8f-6dc2bb509e06', 'panel_kassza_zarasa_figdef_worker_ext3', 'Kassza zárása', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('f716d3e6-72d5-415f-ec90-7ed3cc61af07', 'panel_bankjegykeszlet_figdef_banknote_inventory_ext', 'Bankjegykészlet', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('0827e2f7-83e6-4260-fd01-8fe4dd72be08', 'panel_napi_tranzakciok_figdef_transaction_ext', 'Napi tranzakciók', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('1938f108-94f7-4371-0e12-90f5ee83cf09', 'panel_valutavaltas_sztorno_figdef_worker_ext6', 'Valutaváltás sztornó', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('2a490019-a508-4482-1f23-a106ff94df0a', 'panel_penztari_korrekcio_figdef_worker_ext7', 'Pénztári korrekció', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('3b5a1f2a-b619-4593-2034-b21700a5e00b', 'panel_ugyfelek_figdef_customer_ext', 'Ügyfelek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('4c6b2e3b-c72a-46a4-3145-c32811b6f10c', 'panel_ugyfelkategoriak_figdef_worker_ext9', 'Ügyfélkategóriák', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('5d7c3d4c-d83b-47b5-4256-d43922c7020d', 'panel_ugyfelpanaszok_figdef_worker_ext10', 'Ügyfélpanaszok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('6e8d4c5d-e94c-48c6-5367-e54a33d8130e', 'panel_szallitmanyigenyek_figdef_scheduled_transfer_ext', 'Szállítmányigények', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('7f9e5b6e-fa5d-49d7-6478-f65b44e9240f', 'panel_szallitmanyok_figdef_branch_transfer_ext', 'Szállítmányok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('80af6a7f-0b6e-4ae8-7589-076c55fa3500', 'panel_keszletoptimalizalas_figdef_balance_adjustment_ext', 'Készletoptimalizálás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('91b07980-1c7f-4bf9-869a-187d660b4601', 'panel_napi_forgalmi_kimutatas_figdef_worker_ext14', 'Napi forgalmi kimutatás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('a2c18891-2d80-4ca0-97ab-298e771c5702', 'panel_napi_zaras_jelentes_figdef_worker_ext15', 'Napi zárás jelentés', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('b3d297a2-3e91-4db1-a8bc-3a9f882d6803', 'panel_kasszaallomany_kimutatas_figdef_worker_ext16', 'Kasszaállomány kimutatás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('c4e3a6b3-4fa2-4ec2-b9cd-4bad993e7904', 'panel_heti_forgalom_figdef_worker_ext17', 'Heti forgalom', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('d5f4b5c4-50b3-4fd3-cade-5cbea04f8a05', 'panel_havi_forgalom_figdef_worker_ext18', 'Havi forgalom', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('e605c4d5-61c4-40e4-dbef-6dcfb1509b06', 'panel_negyedeves_eves_forgalom_figdef_worker_ext19', 'Negyedéves/éves forgalom', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('f716d3e6-72d5-41f5-ecf0-7ed0c261ac07', 'panel_arfolyamnyereseg_kimutatas_figdef_worker_ext20', 'Árfolyamnyereség-kimutatás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('0827e2f7-83e6-4206-fd01-8fe1d372bd08', 'panel_jutalekbevetel_kimutatas_figdef_worker_ext21', 'Jutalékbevétel-kimutatás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('1938f108-94f7-4317-0e12-90f2e483ce09', 'panel_fiok_teljesitmeny_figdef_worker_ext22', 'Fiók teljesítmény', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('2a490019-a508-4428-1f23-a103f594df0a', 'panel_fiok_keszletek_figdef_worker_ext23', 'Fiók készletek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('3b5a1f2a-b619-4539-2034-b21406a5e00b', 'panel_fiok_tranzakciok_figdef_worker_ext24', 'Fiók tranzakciók', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('4c6b2e3b-c72a-464a-3145-c32517b6f10c', 'panel_nagy_osszegu_tranzakciok_jelentese_figdef_worker_ext25', 'Nagy összegű tranzakciók jelentése', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('5d7c3d4c-d83b-475b-4256-d43628c7020d', 'panel_gyanus_tranzakciok_jelentese_figdef_worker_ext26', 'Gyanús tranzakciók jelentése', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('6e8d4c5d-e94c-486c-5367-e54739d8130e', 'panel_egyeb_hatosagi_jelentesek_figdef_worker_ext27', 'Egyéb hatósági jelentések', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('7f9e5b6e-fa5d-497d-6478-f6584ae9240f', 'panel_tranzakcios_mintak_elemzese_figdef_worker_ext28', 'Tranzakciós minták elemzése', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('80af6a7f-0b6e-4a8e-7589-07695bf03500', 'panel_ugyfelviselkedes_elemzes_figdef_worker_ext29', 'Ügyfélviselkedés-elemzés', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('91b07980-1c7f-4b9f-869a-18706cf14601', 'panel_szezonalitas_elemzes_figdef_worker_ext30', 'Szezonalitás-elemzés', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('a2c18891-2d80-4ca0-97ab-29817df25702', 'panel_jovedelmezoseg_elemzes_figdef_worker_ext31', 'Jövedelmezőség-elemzés', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('b3d297a2-3e91-4db1-a8bc-3a928e036803', 'panel_devizanemek_figdef_currency_ext', 'Devizanemek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('c4e3a6b3-4fa2-4ec2-b9cd-4ba39f147904', 'panel_cimletoptimalizalas_figdef_denomination_optimization', 'Címletoptimalizálás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('d5f4b5c4-50b3-4fd3-cade-5cb4a0258a05', 'panel_kozponti_arfolyamok_figdef_exchange_rate', 'Központi árfolyamok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('e605c4d5-61c4-40e4-dbef-6dc5b1369b06', 'panel_fiokspecifikus_arfolyamok_figdef_branch_exchange_rate_ext', 'Fiókspecifikus árfolyamok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('f716d3e6-72d5-41f5-ecf0-7ed6c247ac07', 'panel_arfolyam_importalas_figdef_worker_ext32', 'Árfolyam importálás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('0827e2f7-83e6-4206-fd01-8fe7d358bd08', 'panel_fiokok_figdef_branch', 'Fiókok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('1938f108-94f7-4317-0e12-90f8e469ce09', 'panel_workers_figdef_worker_ext', 'workers', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('2a490019-a508-4428-1f23-a109f57adf0a', 'panel_penztarosok_figdef_cashier_ext', 'Pénztárosok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('3b5a1f2a-b619-4539-2034-b21a068be00b', 'panel_myprofile_system_myprofile', 'myProfile', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('4c6b2e3b-c72a-464a-3145-c32b179cf10c', 'panel_usergroups_figdef_role', 'userGroups', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('5d7c3d4c-d83b-475b-4256-d43c28adf20d', 'panel_users_figdef_ruser_ext', 'users', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('6e8d4c5d-e94c-486c-5367-e54d39bef30e', 'panel_altalanos_parameterek_figdef_system_parameter_ext', 'Általános paraméterek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('7f9e5b6e-fa5d-497d-6478-f65e4af0040f', 'panel_arfolyam_parameterek_figdef_company_ext', 'Árfolyam-paraméterek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('80af6a7f-0b6e-4a8e-7589-076f5b011500', 'panel_jutalek_parameterek_figdef_company_ext', 'Jutalék-paraméterek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('91b07980-1c7f-4b9f-869a-18706c122601', 'panel_keszlethatarok_figdef_company_ext', 'Készlethatárok', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('a2c18891-2d80-4ca0-97ab-29817d233702', 'panel_biztonsagi_parameterek_figdef_company_ext', 'Biztonsági paraméterek', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('b3d297a2-3e91-4db1-a8bc-3a928e344803', 'panel_naplo_megtekintese_system_importpartners1', 'Napló megtekintése', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('c4e3a6b3-4fa2-4ec2-b9cd-4ba39f455904', 'panel_audit_naplo_figdef_audit_log_ext', 'Audit napló', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('d5f4b5c4-50b3-4fd3-cade-5cb4a0566a05', 'panel_biztonsagi_esemenyek_system_importpartners2', 'Biztonsági események', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('e605c4d5-61c4-40e4-dbef-6dc5b1677b06', 'panel_naplo_exportalasa_system_importpartners5', 'Napló exportálása', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('f716d3e6-72d5-41f5-ecf0-7ed6c2788c07', 'panel_biztonsagi_mentes_system_importpartners3', 'Biztonsági mentés', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('0827e2f7-83e6-4206-fd01-8fe7d3899d08', 'panel_adatbazis_karbantartas_system_importproductpricelist', 'Adatbázis-karbantartás', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('1938f108-94f7-4317-0e12-90f8e49aa009', 'panel_verzioinformaciok_system_importproductpricelist1', 'Verzióinformációk', NULL, NULL);
INSERT INTO "figdef" ("id", "name", "label", "figdef_id", "visible") VALUES
('2a490019-a508-4428-1f23-a109f5abb10a', 'panel_rendszerteljesitmeny_system_importproductpricelist2', 'Rendszerteljesítmény', NULL, NULL);

INSERT INTO "exchange_rate" ("id", "currency_id", "rate_date", "buy_rate", "mid_rate", "sell_rate", "is_active", "validation_date", "expiration_date") VALUES
('019755b6-32b6-7f98-9852-21da75269636', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', '2025-07-24', 396, 398, 400, true, '2025-07-24', '2025-07-25');
INSERT INTO "exchange_rate" ("id", "currency_id", "rate_date", "buy_rate", "mid_rate", "sell_rate", "is_active", "validation_date", "expiration_date") VALUES
('019755b6-32b6-7f98-9852-21db75269636', '018f3eda-d88e-7786-8043-a4c7f6b1e9f2', '2025-07-24', 366, 368, 370, true, '2025-07-24', '2025-07-25');

INSERT INTO person (id, code, citizenship_1_did, citizenship_2_did, last_name, first_name, uniquemark, title, birth_last_name, birth_first_name, birth_date, birthplace, birthday_notification_flag, name_day_notification_flag, mothers_name, disabled_flag, pension_flag, shoe_size, pants_size, upper_part_size, cap_size, glove_size, without_address_flag) VALUES ('01944f6e-c48e-7a30-9f8f-fe14346162f7', 'D003', '01940704-87ee-7aff-ac11-603938fff434', null, 'Hámori', 'Zoltán', null, null, 'Hámori', 'Zoltán', '1984-10-12', 'Vác', null, null, 'Kusztván Éva', null, null, null, null, null, null, null, null);

INSERT INTO worker (id, person_id, employment_type_did, worker_status_did, payroll_type_did, company_id, feor_did, position, entry_date, leaving_date, weekly_working_hours, other_labor_notice, method_of_termination_did, method_of_termination_desc) VALUES ('01944f6e-c54e-7d4d-8be8-ad70ec9c2c6d', '01944f6e-c48e-7a30-9f8f-fe14346162f7', '019406fc-ef89-733e-b64a-6c6254d42d43', '01940701-d5e6-7fcd-afba-08bb361964dd', '01940700-b1cb-76b3-9fa4-515c532a677d', '01940841-da54-7dee-a346-b2610943e988', null, null, '2020-11-03', null, 40, null, null, null);

INSERT INTO branch (id, code, company_id, bank_code, branch_type_did, parent_branch_id, name, address, city, zip_code, country_did, phone, email, branch_status_did, opening_date, denomination_rule_id) VALUES ('019927b2-5dd9-7435-8d0c-0c7fc06a8215', 'P001', '01940841-da54-7dee-a346-b2610943e988', 'P001', '0196de8d-20a9-7b0a-9450-1d804a12d099', null, 'Pénztár1', 'Dobó tér 13.', 'Eger', '3300', '019406fa-d0ab-74cf-9334-c56ea0357188', '+36(70)123-4567', 'info@info.com', '0196e7ba-06d1-735a-9158-b3fb88c0e9bf', '2025-09-08', null);

INSERT INTO band_exchange_rate_discount (id, currency_id, from_amount, to_amount, discount, validation_date, expiration_date) VALUES ('019927d1-b9c7-78b7-a103-68504f1363ab', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0, 1000, 0.5, '2025-09-08 07:34:21.047763', null);
INSERT INTO band_exchange_rate_discount (id, currency_id, from_amount, to_amount, discount, validation_date, expiration_date) VALUES ('019927dd-035b-7095-a5bd-41027268f3a0', '018f3eda-d0c3-7f8a-97e2-93b8f7c5d1e0', 0, 1000, 1, '2025-09-08 07:46:51.171113', null);

commit;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;

