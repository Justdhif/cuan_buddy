import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query, Request } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  create(@Request() req: any, @Body() createCategoryDto: any) {
    return this.categoriesService.create(req.user.userId, createCategoryDto);
  }

  @Get()
  findAll(@Request() req: any, @Query() query: any) {
    return this.categoriesService.findAll(req.user.userId, query);
  }

  @Get(':slug')
  findOne(@Request() req: any, @Param('slug') slug: string) {
    return this.categoriesService.findOne(req.user.userId, slug);
  }

  @Patch(':slug')
  update(@Request() req: any, @Param('slug') slug: string, @Body() updateCategoryDto: any) {
    return this.categoriesService.update(req.user.userId, slug, updateCategoryDto);
  }

  @Delete(':slug')
  remove(@Request() req: any, @Param('slug') slug: string) {
    return this.categoriesService.remove(req.user.userId, slug);
  }
}
