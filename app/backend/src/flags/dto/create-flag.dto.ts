import { IsString, IsOptional, IsObject } from 'class-validator';

export class CreateFlagDto {
  @IsString()
  key!: string;

  @IsString()
  name!: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsObject()
  @IsOptional()
  environments?: {
    dev?: boolean;
    staging?: boolean;
    production?: boolean;
  };
}
