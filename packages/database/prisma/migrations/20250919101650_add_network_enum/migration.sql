-- CreateEnum
CREATE TYPE "Network" AS ENUM ('Testnet', 'Mainnet');

-- AlterTable
ALTER TABLE "funding_rates" ADD COLUMN "network" "Network" NOT NULL DEFAULT 'Mainnet';

-- CreateIndex
CREATE INDEX "funding_rates_network_idx" ON "funding_rates"("network");