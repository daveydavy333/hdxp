for f in ce pfp me mec rlc sdma uvd vce; do
    rm -f "/lib/firmware/amdgpu/stoney_$f.bin"
done
rmdir /lib/firmware/amdgpu 2>/dev/null || true
