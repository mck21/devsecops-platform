import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { LoggerModule } from 'nestjs-pino';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';
import { PrismaModule } from './prisma/prisma.module';
import { CacheConfigModule } from './cache/cache.module';
import { FlagsModule } from './flags/flags.module';
import { AuditModule } from './audit/audit.module';
import { HealthModule } from './health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    LoggerModule.forRoot({
      pinoHttp: {
        genReqId: (req) =>
          (req.headers['x-request-id'] as string) ?? crypto.randomUUID(),
        transport:
          process.env.NODE_ENV !== 'production'
            ? { target: 'pino-pretty', options: { singleLine: true } }
            : undefined,
        customProps: (req) => ({ requestId: req.id }),
      },
    }),
    PrometheusModule.register({
      path: '/metrics',
      defaultMetrics: { enabled: true },
    }),
    PrismaModule,
    CacheConfigModule,
    FlagsModule,
    AuditModule,
    HealthModule,
  ],
})
export class AppModule {}
