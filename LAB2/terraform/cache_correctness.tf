# Cache policy for static content.
# Static files should be cached aggressively because they do not change every request.
resource "aws_cloudfront_cache_policy" "static_cache_policy" {
  name        = "lab2-static-cache-policy"
  comment     = "Cache policy for static LAB2 content"
  default_ttl = 86400 # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0 # allow cache to be bypassed if needed

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none" # static content does not need cookies, and this allows more cache hits by ignoring irrelevant cookies
    }

    headers_config {
      header_behavior = "none" # static content does not need headers, and this allows more cache hits by ignoring irrelevant headers
    }

    query_strings_config {
      query_string_behavior = "none" # static content does not need query strings, and this allows more cache hits by ignoring irrelevant query strings
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

# Cache policy for dynamic/app traffic.
# This disables caching so dynamic endpoints are always fetched from the origin.
resource "aws_cloudfront_cache_policy" "dynamic_no_cache_policy" {
  name        = "lab2-dynamic-no-cache-policy"
  comment     = "Do not cache dynamic LAB2 application traffic"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none" # dynamic content does not need cookies, and this allows more cache hits by ignoring irrelevant cookies
    }

    headers_config {
      header_behavior = "none" # dynamic content does not need headers, and this allows more cache hits by ignoring irrelevant headers
    }

    query_strings_config {
      query_string_behavior = "none" # dynamic content does not need query strings, and this allows more cache hits by ignoring irrelevant query strings
    }
  }
}

# Origin request policy for static content.
# Static requests do not need extra cookies/headers/query strings forwarded to the ALB.
resource "aws_cloudfront_origin_request_policy" "static_origin_request_policy" {
  name    = "lab2-static-origin-policy"
  comment = "Minimal origin forwarding for static content"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }
}

# Origin request policy for dynamic/app traffic.
# Dynamic requests should preserve query strings and useful request context.
resource "aws_cloudfront_origin_request_policy" "dynamic_origin_request_policy" {
  name    = "lab2-dynamic-origin-policy"
  comment = "Forward dynamic request details to the origin"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"

    headers {
      items = ["Host"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# Response headers policy for static content.
# This helps make static caching behavior more explicit at the edge/client side.
resource "aws_cloudfront_response_headers_policy" "static_response_headers_policy" {
  name    = "lab2-static-response-headers"
  comment = "Response headers for static cached content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      value    = "public, max-age=86400"
      override = true
    }
  }
}