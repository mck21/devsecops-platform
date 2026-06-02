-- CreateTable
CREATE TABLE "Flag" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "environments" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Flag_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "flagKey" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "environment" TEXT NOT NULL,
    "previousValue" BOOLEAN,
    "newValue" BOOLEAN,
    "performedBy" TEXT NOT NULL DEFAULT 'system',
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Flag_key_key" ON "Flag"("key");

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_flagKey_fkey" FOREIGN KEY ("flagKey") REFERENCES "Flag"("key") ON DELETE RESTRICT ON UPDATE CASCADE;
