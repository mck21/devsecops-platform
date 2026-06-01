import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    // 1. Create a native pg connection pool using your environment variable
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    
    // 2. Instantiate the Prisma driver adapter
    const adapter = new PrismaPg(pool);

    // 3. Pass the adapter directly to the super constructor
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}