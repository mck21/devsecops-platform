import { Module } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { CacheModule } from '@nestjs/cache-manager';
import { LoggerModule } from 'nestjs-pino';
import { PrometheusModule } from '@willsoto/nestjs-prometheus';
import request from 'supertest';
import { App } from 'supertest/types';
import { PrismaService } from '../src/prisma/prisma.service';
import { PrismaModule } from '../src/prisma/prisma.module';
import { FlagsModule } from '../src/flags/flags.module';
import { AuditModule } from '../src/audit/audit.module';
import { HealthModule } from '../src/health/health.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    LoggerModule.forRoot({ pinoHttp: { autoLogging: false } }),
    PrometheusModule.register({
      path: '/metrics',
      defaultMetrics: { enabled: true },
    }),
    CacheModule.register({ isGlobal: true }),
    PrismaModule,
    FlagsModule,
    AuditModule,
    HealthModule,
  ],
})
class TestAppModule {}

describe('Feature Flag Service (e2e)', () => {
  let app: INestApplication<App>;

  const mockPrisma = {
    $connect: jest.fn(),
    $disconnect: jest.fn(),
    $queryRaw: jest.fn().mockResolvedValue(1),
    flag: {
      create: jest.fn(),
      findMany: jest.fn().mockResolvedValue([]),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({}),
      findMany: jest.fn().mockResolvedValue([]),
    },
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [TestAppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });

  afterEach(async () => {
    await app?.close();
  });

  it('/health (GET)', () => {
    return request(app.getHttpServer())
      .get('/health')
      .expect(200)
      .expect((res) => {
        expect(res.body.status).toBe('ok');
        expect(res.body.info.postgresql.status).toBe('up');
        expect(res.body.info.redis.status).toBe('up');
      });
  });

  it('/metrics (GET)', () => {
    return request(app.getHttpServer())
      .get('/metrics')
      .expect(200)
      .expect('Content-Type', /text\/plain/);
  });

  it('/api/audit (GET)', () => {
    return request(app.getHttpServer()).get('/api/audit').expect(200);
  });
});
