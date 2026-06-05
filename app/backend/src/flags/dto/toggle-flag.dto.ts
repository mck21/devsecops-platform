import { IsString, IsIn } from 'class-validator';

export class ToggleFlagDto {
  @IsString()
  @IsIn(['dev', 'staging', 'production'])
  environment!: string;
}