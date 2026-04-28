-- wrk Lua script: CDN baseline throughput with deep path randomization
-- Each request gets a random path, random XFF IP, random Accept-Encoding, random User-Agent

local counter = 0

-- RFC 5737 test-net ranges
local test_nets = {"192.0.2", "198.51.100", "203.0.113"}

local encodings = {"gzip", "br", "gzip, deflate", "gzip, deflate, br", "identity"}

local user_agents = {
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1",
  "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Edg/125.0",
  "Mozilla/5.0 (iPad; CPU OS 17_5) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1",
  "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
  "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
  "curl/8.7.1",
  "python-requests/2.31.0",
  "Go-http-client/2.0",
  "PostmanRuntime/7.39.0",
  "Playwright/1.45.0",
}

local search_words = {
  "apple", "banana", "cherry", "orange", "lemon", "melon", "grape", "mango",
  "peach", "berry", "juice", "water", "milk", "coffee", "tea", "beer",
  "wine", "soda", "cake", "bread", "rice", "fish", "meat", "egg",
}

local user_names = {
  "alice", "bob", "charlie", "dave", "eve", "frank", "grace", "heidi",
  "ivan", "judy", "karl", "laura", "mike", "nancy", "oscar", "pat",
}

-- Deep path catalogs per app
local function rand_juice_shop()
  local r = math.random(1, 10)
  if r <= 3 then return "/juice-shop/"
  elseif r == 4 then return "/juice-shop/rest/products/search?q=" .. search_words[math.random(#search_words)]
  elseif r == 5 then return "/juice-shop/api/Products/" .. math.random(1, 50)
  elseif r == 6 then return "/juice-shop/api/Challenges/"
  elseif r == 7 then return "/juice-shop/api/SecurityQuestions/"
  elseif r == 8 then return "/juice-shop/rest/languages"
  elseif r == 9 then return "/juice-shop/ftp/"
  else return "/juice-shop/rest/admin/application-configuration"
  end
end

local function rand_dvwa()
  local paths = {
    "/dvwa/login.php", "/dvwa/vulnerabilities/", "/dvwa/vulnerabilities/sqli/",
    "/dvwa/vulnerabilities/xss_r/", "/dvwa/vulnerabilities/fi/",
    "/dvwa/vulnerabilities/upload/", "/dvwa/setup.php", "/dvwa/security.php",
    "/dvwa/vulnerabilities/exec/", "/dvwa/vulnerabilities/csrf/",
  }
  return paths[math.random(#paths)]
end

local function rand_vampi()
  local paths = {"/vampi/", "/vampi/users/v1", "/vampi/posts/v1", "/vampi/users/v1/_default_admin/posts"}
  return paths[math.random(#paths)]
end

local function rand_httpbin()
  local r = math.random(1, 10)
  if r <= 2 then return "/httpbin/get"
  elseif r == 3 then return "/httpbin/get?user=" .. user_names[math.random(#user_names)]
  elseif r == 4 then return "/httpbin/headers"
  elseif r == 5 then return "/httpbin/ip"
  elseif r == 6 then return "/httpbin/user-agent"
  elseif r == 7 then return "/httpbin/anything/" .. user_names[math.random(#user_names)]
  elseif r == 8 then return "/httpbin/status/" .. ({200, 201, 301, 404})[math.random(4)]
  elseif r == 9 then return "/httpbin/response-headers?X-Test=" .. math.random(1, 9999)
  else return "/httpbin/get?ts=" .. os.time() .. "&r=" .. math.random(1, 99999)
  end
end

local function rand_path()
  local r = math.random(1, 7)
  if r == 1 then return rand_juice_shop()
  elseif r == 2 then return rand_dvwa()
  elseif r == 3 then return rand_vampi()
  elseif r == 4 then return rand_httpbin()
  elseif r == 5 then return "/csd-demo/" .. ({"", "health"})[math.random(2)]
  elseif r == 6 then return "/whoami/"
  else return "/health"
  end
end

local function rand_ip()
  return test_nets[math.random(#test_nets)] .. "." .. math.random(0, 255)
end

request = function()
  counter = counter + 1
  local path = rand_path()
  local ip = rand_ip()
  local enc = encodings[math.random(#encodings)]
  local ua = user_agents[math.random(#user_agents)]

  wrk.headers["X-Forwarded-For"] = ip
  wrk.headers["True-Client-IP"] = ip
  wrk.headers["CF-Connecting-IP"] = ip
  wrk.headers["Fastly-Client-IP"] = ip
  wrk.headers["Accept-Encoding"] = enc
  wrk.headers["User-Agent"] = ua
  wrk.headers["Cookie"] = "session=wrk-" .. (counter % 500)

  return wrk.format("GET", path)
end
