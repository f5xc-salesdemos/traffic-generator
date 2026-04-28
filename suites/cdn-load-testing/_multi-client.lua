-- wrk Lua script: Multi-client IP simulation
-- Focuses on maximizing client diversity via CDN vendor headers
-- Each request simulates a unique client with correlated IP across all vendor headers

local thread_id = 0
local request_counter = 0

local test_nets = {"192.0.2", "198.51.100", "203.0.113"}

local user_agents = {
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5) AppleWebKit/605.1.15 Mobile Safari/604.1",
  "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Edg/125.0",
  "Mozilla/5.0 (iPad; CPU OS 17_5) AppleWebKit/605.1.15 Mobile Safari/604.1",
  "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 OPR/110.0",
  "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:127.0) Gecko/20100101 Firefox/127.0",
  "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
  "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
  "curl/8.7.1",
  "python-requests/2.31.0",
  "Go-http-client/2.0",
  "PostmanRuntime/7.39.0",
  "Playwright/1.45.0",
  "HeadlessChrome/125.0",
  "Scrapy/2.11.2",
  "Apache-HttpClient/4.5.14",
  "okhttp/4.12.0",
  "axios/1.7.2",
  "node-fetch/3.3.2",
}

local countries = {"US", "GB", "DE", "FR", "JP", "AU", "CA", "BR", "IN", "KR", "SG", "NL", "SE", "IT", "ES"}
local cities = {"New York", "London", "Berlin", "Paris", "Tokyo", "Sydney", "Toronto", "Sao Paulo", "Mumbai", "Seoul"}

-- Per-app endpoint paths
local endpoints = {
  "/juice-shop/",
  "/juice-shop/rest/products/search?q=test",
  "/dvwa/login.php",
  "/vampi/users/v1",
  "/httpbin/get",
  "/httpbin/headers",
  "/csd-demo/health",
  "/whoami/",
  "/health",
}

local function rand_ip()
  return test_nets[math.random(#test_nets)] .. "." .. math.random(0, 255)
end

setup = function(thread)
  thread:set("id", thread_id)
  thread_id = thread_id + 1
end

init = function(args)
  request_counter = 0
end

request = function()
  request_counter = request_counter + 1
  local ip = rand_ip()
  local ua = user_agents[math.random(#user_agents)]
  local country = countries[math.random(#countries)]
  local city = cities[math.random(#cities)]
  local path = endpoints[math.random(#endpoints)]
  local session_id = string.format("sess-%d-%d", id or 0, request_counter % 200)

  -- Standard proxy headers
  wrk.headers["X-Forwarded-For"] = ip
  wrk.headers["X-Forwarded-Proto"] = "https"
  wrk.headers["X-Real-IP"] = ip

  -- Akamai headers
  wrk.headers["True-Client-IP"] = ip
  wrk.headers["X-Akamai-Edgescape"] = "country_code=" .. country .. ",city=" .. city

  -- Cloudflare headers
  wrk.headers["CF-Connecting-IP"] = ip
  wrk.headers["CF-IPCountry"] = country
  wrk.headers["cf-ipcity"] = city

  -- CloudFront headers
  wrk.headers["CloudFront-Viewer-Address"] = ip .. ":443"
  wrk.headers["CloudFront-Viewer-Country"] = country

  -- Fastly headers
  wrk.headers["Fastly-Client-IP"] = ip
  wrk.headers["X-Geo-Country-Code"] = country
  wrk.headers["X-Geo-City"] = city

  -- Azure Front Door
  wrk.headers["X-Azure-ClientIP"] = ip
  wrk.headers["X-Azure-SocketIP"] = ip

  -- Request diversity
  wrk.headers["User-Agent"] = ua
  wrk.headers["Accept-Encoding"] = ({"gzip", "br", "gzip, deflate", "gzip, deflate, br", "identity"})[math.random(5)]
  wrk.headers["Cookie"] = "session=" .. session_id

  return wrk.format("GET", path)
end
