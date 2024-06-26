const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));



async function call_api_with_retry_logic(api_call, max_retries = 5, default_delay = 5, secondary_rate_limit_delay_base = 60, delay_function = delay) {
  for (let i = 0; i < max_retries; i++) {
    try {
      return await api_call();
    } catch (error) {
      console.error(`Attempt ${i + 1} failed: ${error.message}`);

      let wait_time;
      if (error.response && error.response.status && error.response.headers) {
        const status = error.response.status;
        const retry_after = error.response.headers["retry-after"];
        const rate_limit_remaining = error.response.headers["x-ratelimit-remaining"];
        const rate_limit_reset = error.response.headers["x-ratelimit-reset"];
        const max_waiting_time = 900;

        if (status === 403) {
          if (rate_limit_remaining === "0") {
            wait_time = rate_limit_reset - Math.floor(Date.now() / 1000);
            if (wait_time > max_waiting_time) {
              console.error(`Rate limit reset time is in ${wait_time} seconds. Operation aborted.`);
              throw error;
            } else {
              console.error(`Rate limit exceeded. Retrying in ${wait_time} seconds...`);
            }
          } else if (retry_after && parseInt(retry_after) > max_waiting_time) {
            console.error(`Retry after time is in ${retry_after} seconds. Operation aborted.`);
            throw error;
          } else if (
            error.response.data.message.includes("secondary rate limit")
          ) {
            wait_time = secondary_rate_limit_delay_base + Math.floor(0.5 * Math.random() * secondary_rate_limit_delay_base);
            console.error(`Secondary rate limit exceeded. Retrying in ${wait_time} seconds...`);
          } else {
            wait_time = parseInt(retry_after);
            console.error(`Rate limit exceeded. Retrying in ${wait_time} seconds...`);
          }
        } else if (status >= 500) {
          wait_time = default_delay;
          console.error(`An internal error occurred on server. Retrying in ${wait_time} seconds...`);
        } else if (status >= 400) {
          console.error(`Client error: ${status}. Operation aborted.`);
          throw error;
        }
      } else {
        wait_time = default_delay;
        console.error(`Unknown error. Retrying in ${wait_time} seconds...`);
      }

      if (i === max_retries - 1) {
        throw error;
      }

      await delay_function(wait_time * 1000);
    }
  }
}



module.exports = call_api_with_retry_logic;
