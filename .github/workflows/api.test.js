const call_api_with_retry_logic = require('./api');

jest.setTimeout(999999);

describe('call_api_with_retry_logic', () => {
  let api_call, delay_function;
  const max_retries = 3;
  const default_delay = 1;
  const secondary_rate_limit_delay_base = 60;
  const max_waiting_time = 900;

  beforeEach(() => {
    api_call = jest.fn();
    delay_function = jest.fn();
  });

  test('should return api_call result when successful', async () => {
    const expected = 'success';
    api_call.mockResolvedValueOnce(expected);

    const result = await call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function);

    expect(result).toEqual(expected);
  });

  test('should retry on error and eventually succeed', async () => {
    const expected = 'success';
    const error = new Error('failure');
    api_call.mockRejectedValueOnce(error).mockResolvedValueOnce(expected);

    const result = await call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function);

    expect(result).toEqual(expected);
    expect(api_call).toHaveBeenCalledTimes(2);
    expect(delay_function).toHaveBeenCalledTimes(1);
    expect(delay_function).toHaveBeenCalledWith(default_delay * 1000);
  });

  test('should throw error when all retries fail', async () => {
    const error = new Error('failure');
    api_call.mockRejectedValue(error);

    await expect(call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function)).rejects.toThrow(error);
    expect(delay_function).toHaveBeenCalledTimes(max_retries-1);
    expect(delay_function).toHaveBeenCalledWith(default_delay * 1000);
  });

  test('should handle 403 status with rate limit exceeded', async () => {
    const error = new Error('failure');
    const seconds_to_wait_before_retry = 2;
    error.response = {
      status: 403,
      headers: {
        'retry-after': '5',
        'x-ratelimit-remaining': '0',
        'x-ratelimit-reset': String(Math.floor(Date.now() / 1000) + seconds_to_wait_before_retry)
      },
      data: {
        message: 'Rate limit exceeded'
      }
    };
    api_call.mockRejectedValueOnce(error).mockResolvedValueOnce('success');

    const result = await call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function);

    expect(result).toEqual('success');
    expect(delay_function).toHaveBeenCalledTimes(1);
    expect(delay_function).toHaveBeenCalledWith(seconds_to_wait_before_retry * 1000);
  });

  test('should handle 403 status with secondary rate limit exceeded', async () => {
    const error = new Error('failure');
    error.response = {
      status: 403,
      headers: {},
      data: {
        message: 'secondary rate limit exceeded'
      }
    };
    api_call.mockRejectedValueOnce(error).mockResolvedValueOnce('success');

    const result = await call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function);

    expect(result).toEqual('success');
    expect(delay_function).toHaveBeenCalledTimes(1);
    const [[wait_time]] = delay_function.mock.calls;
    expect(wait_time).toBeGreaterThanOrEqual(secondary_rate_limit_delay_base*1000);
  });

  test('should handle 500 status', async () => {
    const error = new Error('failure');
    error.response = {
      status: 500,
      headers: {},
      data: {
        message: 'Server error'
      }
    };
    api_call.mockRejectedValueOnce(error).mockResolvedValueOnce('success');

    const result = await call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function);

    expect(result).toEqual('success');
    expect(delay_function).toHaveBeenCalledTimes(1);
    expect(delay_function).toHaveBeenCalledWith(default_delay * 1000);
  });

  test('should handle 400 status and abort operation', async () => {
    const error = new Error('failure');
    error.response = {
      status: 400,
      headers: {},
      data: {
        message: 'Bad request'
      }
    };
    api_call.mockRejectedValueOnce(error);

    await expect(call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function)).rejects.toThrow(error);
    expect(api_call).toHaveBeenCalledTimes(1);
    expect(delay_function).not.toHaveBeenCalled();
  });

  test('should handle 403 status with retry after exceeding max waiting time', async () => {
    const error = new Error('failure');
    error.response = {
      status: 403,
      headers: {
        'retry-after': `${max_waiting_time + 1}`,
      },
      data: {
        message: 'Rate limit exceeded'
      }
    };
    api_call.mockRejectedValueOnce(error);

    await expect(call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function)).rejects.toThrow(error);
    expect(api_call).toHaveBeenCalledTimes(1);
    expect(delay_function).not.toHaveBeenCalled();
  });

  test('should handle 403 status with rate limit reset time exceeding max waiting time', async () => {
    const error = new Error('failure');
    error.response = {
      status: 403,
      headers: {
        'x-ratelimit-remaining': '0',
        'x-ratelimit-reset': String(Math.floor(Date.now() / 1000) + max_waiting_time + 1)
      },
      data: {
        message: 'Rate limit exceeded'
      }
    };
    api_call.mockRejectedValueOnce(error);

    await expect(call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function)).rejects.toThrow(error);
    expect(api_call).toHaveBeenCalledTimes(1);
    expect(delay_function).not.toHaveBeenCalled();
  });

  test('should handle non-403 4xx status', async () => {
    const error = new Error('failure');
    error.response = {
      status: 400,
      headers: {},
      data: {
        message: 'Bad request'
      }
    };
    api_call.mockRejectedValueOnce(error);

    await expect(call_api_with_retry_logic(api_call, max_retries, default_delay, secondary_rate_limit_delay_base, delay_function)).rejects.toThrow(error);
    expect(api_call).toHaveBeenCalledTimes(1);
    expect(delay_function).not.toHaveBeenCalled();
  });
});
