
SET(yps_SOURCES yps.c)
ADD_EXECUTABLE(yps ${yps_SOURCES})
TARGET_LINK_LIBRARIES(yps satsolver)

SET(gimmick_SOURCES gimmick.c)
ADD_EXECUTABLE(gimmick ${gimmick_SOURCES})
TARGET_LINK_LIBRARIES(gimmick satsolver)


SET(deptestomatic_SOURCES deptestomatic.c)
ADD_EXECUTABLE(deptestomatic ${deptestomatic_SOURCES})
TARGET_LINK_LIBRARIES(deptestomatic satsolver ${EXPAT_LIBRARY})

