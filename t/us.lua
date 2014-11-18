
ffi.cdef[[

        struct timeval {
                long int tv_sec;
                long int tv_usec;
        };
        int gettimeofday(struct timeval *tv, void *tz);
]];

local tm = ffi.new("struct timeval");
function NewTimeKey()
        ffi.C.gettimeofday(tm, nil)
        local sec = tonumber(tm.tv_sec)
        local usec = tonumber(tm.tv_usec);

        print("second : " .. tostring(sec))
        print("usecond : " .. tostring(usec))
        print("result : " .. tostring(sec) .. "." .. tostring(usec))
end

NewTimeKey()
