-- CreateTable
CREATE TABLE "funding_rates" (
    "id" SERIAL NOT NULL,
    "ticker" TEXT NOT NULL,
    "fundingRate" TEXT NOT NULL,
    "readingTime" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "funding_rates_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "funding_rates_ticker_idx" ON "funding_rates"("ticker");

-- CreateIndex
CREATE INDEX "funding_rates_createdAt_idx" ON "funding_rates"("createdAt");
