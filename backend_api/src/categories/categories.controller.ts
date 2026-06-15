import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Query } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  create(@Body() createCategoryDto: any) {
    return this.categoriesService.create(createCategoryDto);
  }

  @Get()
  findAll(@Query() query: any) {
    return this.categoriesService.findAll(query);
  }

  @Get(':slug')
  findOne(@Param('slug') slug: string) {
    return this.categoriesService.findOne(slug);
  }

  @Patch(':slug')
  update(@Param('slug') slug: string, @Body() updateCategoryDto: any) {
    return this.categoriesService.update(slug, updateCategoryDto);
  }

  @Delete(':slug')
  remove(@Param('slug') slug: string) {
    return this.categoriesService.remove(slug);
  }
}
