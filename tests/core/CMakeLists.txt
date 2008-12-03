IF (CHECK_FOUND)
ADD_TESTS(solv)
ELSE (CHECK_FOUND)
  MESSAGE(STATUS "**** 'check' not found, skipping tests")
ENDIF (CHECK_FOUND)

