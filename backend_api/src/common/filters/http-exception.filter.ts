import { ExceptionFilter, Catch, ArgumentsHost, HttpException } from '@nestjs/common';
import { Response } from 'express';

@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status = exception.getStatus();
    const exceptionResponse: any = exception.getResponse();

    let message = exception.message;
    let errorStr = 'Error';

    if (typeof exceptionResponse === 'object') {
      message = exceptionResponse.message || exception.message;
      errorStr = exceptionResponse.error || exception.name;
    } else if (typeof exceptionResponse === 'string') {
      message = exceptionResponse;
    }

    // Custom English Error Messages for common errors
    if (status === 401 && message === 'Unauthorized') {
      message = 'You are unauthenticated. Please log in to access this resource.';
    } else if (status === 403 && message === 'Forbidden resource') {
      message = 'You are not authorized to access this resource (Forbidden).';
    }

    response
      .status(status)
      .json({
        status: false,
        statusCode: status,
        message: message,
        error: errorStr,
      });
  }
}
