import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFlagDto } from './dto/create-flag.dto';
import { ToggleFlagDto } from './dto/toggle-flag.dto';

@Injectable()
export class FlagsService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(CACHE_MANAGER) private readonly cache: Cache,
  ) {}

  async create(dto: CreateFlagDto) {
    return this.prisma.flag.create({
      data: {
        key: dto.key,
        name: dto.name,
        description: dto.description,
        environments: dto.environments ?? {
          dev: false,
          staging: false,
          production: false,
        },
      },
    });
  }

  async findAll(env?: string) {
    const flags = await this.prisma.flag.findMany();
    if (env) {
      return flags.filter((f) => {
        const envs = f.environments as Record<string, boolean>;
        return envs[env] !== undefined;
      });
    }
    return flags;
  }

  async findOne(key: string) {
    const cacheKey = `flag:${key}`;
    const cached = await this.cache.get(cacheKey);
    if (cached) return cached;

    const flag = await this.prisma.flag.findUnique({ where: { key } });
    if (!flag) throw new NotFoundException(`Flag "${key}" not found`);

    await this.cache.set(cacheKey, flag);
    return flag;
  }

  async toggle(key: string, dto: ToggleFlagDto) {
    const flag = await this.prisma.flag.findUnique({ where: { key } });
    if (!flag) throw new NotFoundException(`Flag "${key}" not found`);

    const envs = flag.environments as Record<string, boolean>;
    const previous = envs[dto.environment];
    envs[dto.environment] = !previous;

    const updated = await this.prisma.flag.update({
      where: { key },
      data: { environments: envs },
    });

    // Invalidate cache
    await this.cache.del(`flag:${key}`);

    return { updated, previousValue: previous, newValue: !previous };
  }

  async remove(key: string) {
    await this.findOne(key);
    await this.cache.del(`flag:${key}`);
    return this.prisma.flag.delete({ where: { key } });
  }
}