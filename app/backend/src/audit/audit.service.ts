import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(data: {
    flagKey: string;
    action: string;
    environment: string;
    previousValue?: boolean;
    newValue?: boolean;
    performedBy?: string;
  }) {
    return this.prisma.auditLog.create({ data });
  }

  async findAll(env?: string) {
    return this.prisma.auditLog.findMany({
      where: env ? { environment: env } : undefined,
      orderBy: { timestamp: 'desc' },
      take: 100,
    });
  }
}