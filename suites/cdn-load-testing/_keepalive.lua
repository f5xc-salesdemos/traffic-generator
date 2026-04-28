-- wrk Lua script: Keepalive-optimized CDN throughput
-- Randomizes paths/headers per request but KEEPS connections alive
-- Key: Connection: keep-alive header is set, wrk reuses TCP connections

local counter = 0

local test_nets = {"192.0.2", "198.51.100", "203.0.113"}

local user_agents = {
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5) AppleWebKit/605.1.15 Mobile Safari/604.1",
  "Mozilla/5.0 (Linux; Android 14; SM-S928B) AppleWebKit/537.36 Chrome/125.0 Mobile Safari/537.36",
}

local search_words = {
  "apple", "banana", "cherry", "orange", "lemon", "melon", "grape", "mango",
  "peach", "berry", "juice", "water", "milk", "coffee", "tea", "beer",
}

local user_names = {
  "alice", "bob", "charlie", "dave", "eve", "frank", "grace", "heidi",
}

local function rand_juice_shop()
  local r = math.random(1, 8)
  if r <= 3 then return "/juice-shop/"
  elseif r == 4 then return "/juice-shop/rest/products/search?q=" .. search_words[math.random(#search_words)]
  elseif r == 5 then return "/juice-shop/api/Products/" .. math.random(1, 50)
  elseif r == 6 then return "/juice-shop/api/Challenges/"
  elseif r == 7 then return "/juice-shop/rest/languages"
  else return "/juice-shop/api/SecurityQuestions/"
  end
end

local function rand_dvwa()
  local paths = {
    "/dvwa/login.php", "/dvwa/vulnerabilities/", "/dvwa/vulnerabilities/sqli/",
    "/dvwa/vulnerabilities/xss_r/", "/dvwa/setup.php", "/dvwa/security.php",
  }
  return paths[math.random(#paths)]
end

local function rand_httpbin()
  local r = math.random(1, 8)
  if r <= 2 then return "/httpbin/get"
  elseif r == 3 then return "/httpbin/get?user=" .. user_names[math.random(#user_names)]
  elseif r == 4 then return "/httpbin/headers"
  elseif r == 5 then return "/httpbin/ip"
  elseif r == 6 then return "/httpbin/user-agent"
  elseif r == 7 then return "/httpbin/anything/" .. user_names[math.random(#user_names)]
  else return "/httpbin/status/200"
  end
end

local function rand_path()
  local r = math.random(1, 7)
  if r == 1 then return rand_juice_shop()
  elseif r == 2 then return rand_dvwa()
  elseif r == 3 then return "/vampi/users/v1"
  elseif r == 4 then return rand_httpbin()
  elseif r == 5 then return "/csd-demo/health"
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

  -- Connection: keep-alive is critical — tells CDN to reuse this TCP connection
  wrk.headers["Connection"] = "keep-alive"
  wrk.headers["X-Forwarded-For"] = ip
  wrk.headers["True-Client-IP"] = ip
  wrk.headers["CF-Connecting-IP"] = ip
  wrk.headers["Accept-Encoding"] = "gzip"
  wrk.headers["User-Agent"] = user_agents[math.random(#user_agents)]

  return wrk.format("GET", path)
end
