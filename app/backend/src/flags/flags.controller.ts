import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { FlagsService } from './flags.service';
import { CreateFlagDto } from './dto/create-flag.dto';
import { ToggleFlagDto } from './dto/toggle-flag.dto';

@Controller('api/flags')
export class FlagsController {
  constructor(private readonly flagsService: FlagsService) {}

  @Post()
  create(@Body() dto: CreateFlagDto) {
    return this.flagsService.create(dto);
  }

  @Get()
  findAll(@Query('env') env?: string) {
    return this.flagsService.findAll(env);
  }

  @Get(':key')
  findOne(@Param('key') key: string) {
    return this.flagsService.findOne(key);
  }

  @Patch(':key/toggle')
  toggle(@Param('key') key: string, @Body() dto: ToggleFlagDto) {
    return this.flagsService.toggle(key, dto);
  }

  @Delete(':key')
  remove(@Param('key') key: string) {
    return this.flagsService.remove(key);
  }
}
