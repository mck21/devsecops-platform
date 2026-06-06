import { Test, TestingModule } from '@nestjs/testing';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { FlagsService } from '../src/flags/flags.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { AuditService } from '../src/audit/audit.service';

describe('FlagsService', () => {
  let service: FlagsService;
  let auditService: { log: jest.Mock };

  const mockFlag = {
    id: '1',
    key: 'dark-mode',
    name: 'Dark Mode',
    description: null,
    environments: { dev: false, staging: false, production: false },
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockPrisma = {
    flag: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  const mockCache = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    auditService = { log: jest.fn().mockResolvedValue({}) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FlagsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: auditService },
        { provide: CACHE_MANAGER, useValue: mockCache },
      ],
    }).compile();

    service = module.get<FlagsService>(FlagsService);
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('creates a flag and writes an audit log', async () => {
      mockPrisma.flag.create.mockResolvedValue(mockFlag);

      const result = await service.create({
        key: 'dark-mode',
        name: 'Dark Mode',
      });

      expect(result).toEqual(mockFlag);
      expect(auditService.log).toHaveBeenCalledWith({
        flagKey: 'dark-mode',
        action: 'create',
        environment: 'all',
      });
    });

    it('throws ConflictException when key already exists', async () => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed',
        { code: 'P2002', clientVersion: '7.8.0' },
      );
      mockPrisma.flag.create.mockRejectedValue(error);

      await expect(
        service.create({ key: 'dark-mode', name: 'Dark Mode' }),
      ).rejects.toThrow(ConflictException);
      expect(auditService.log).not.toHaveBeenCalled();
    });
  });

  describe('toggle', () => {
    it('toggles a flag and writes an audit log', async () => {
      mockPrisma.flag.findUnique.mockResolvedValue(mockFlag);
      mockPrisma.flag.update.mockResolvedValue({
        ...mockFlag,
        environments: { ...mockFlag.environments, dev: true },
      });

      const result = await service.toggle('dark-mode', { environment: 'dev' });

      expect(result.previousValue).toBe(false);
      expect(result.newValue).toBe(true);
      expect(mockCache.del).toHaveBeenCalledWith('flag:dark-mode');
      expect(auditService.log).toHaveBeenCalledWith({
        flagKey: 'dark-mode',
        action: 'toggle',
        environment: 'dev',
        previousValue: false,
        newValue: true,
      });
    });

    it('throws when flag does not exist', async () => {
      mockPrisma.flag.findUnique.mockResolvedValue(null);

      await expect(
        service.toggle('missing', { environment: 'dev' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('deletes a flag and writes an audit log', async () => {
      mockCache.get.mockResolvedValue(null);
      mockPrisma.flag.findUnique.mockResolvedValue(mockFlag);
      mockPrisma.flag.delete.mockResolvedValue(mockFlag);

      await service.remove('dark-mode');

      expect(mockCache.del).toHaveBeenCalledWith('flag:dark-mode');
      expect(auditService.log).toHaveBeenCalledWith({
        flagKey: 'dark-mode',
        action: 'delete',
        environment: 'all',
      });
    });
  });
});
