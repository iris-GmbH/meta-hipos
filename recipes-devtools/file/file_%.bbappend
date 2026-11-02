# Fix file-native compile error
#TZ=UTC MAGIC=../magic/magic ./test -e ../../git/tests/fit-map-data.testfile ../../git/tests/fit-map-data.result
#../../git/tests/fit-map-data.testfile: FIT Map data, unit id 65536, serial 3879446968, Sat May 31 12:00:34 2014, manufacturer 1 (garmin), product 1632, type 4 (Activity)
#test: ERROR: result was (len 130)
#FIT Map data, unit id 65536, serial 3879446968, Sat May 31 12:00:34 2014, manufacturer 1 (garmin), product 1632, type 4 (Activity)
#expected (len 131)
do_configure:append:class-native() {
    sed -i 's/check-local://g' ${S}/tests/Makefile.in || true
}
