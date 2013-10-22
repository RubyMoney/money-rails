CREATE TABLE "dummy_products" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "currency" varchar(255), "price_cents" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "products" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "price_cents" integer, "discount" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL, "bonus_cents" integer, "optional_price_cents" integer, "sale_price_amount" integer DEFAULT 0 NOT NULL, "sale_price_currency_code" varchar(255), "price_in_a_range_cents" integer);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "services" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "charge_cents" integer, "discount_cents" integer, "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE TABLE "transactions" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "amount_cents" integer, "tax_cents" integer, "currency" varchar(255), "created_at" datetime NOT NULL, "updated_at" datetime NOT NULL);
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20120331190108');

INSERT INTO schema_migrations (version) VALUES ('20120402080348');

INSERT INTO schema_migrations (version) VALUES ('20120524052716');

INSERT INTO schema_migrations (version) VALUES ('20120528181002');

INSERT INTO schema_migrations (version) VALUES ('20120528210103');

INSERT INTO schema_migrations (version) VALUES ('20120607210247');

INSERT INTO schema_migrations (version) VALUES ('20120712202655');

INSERT INTO schema_migrations (version) VALUES ('20130124023419');