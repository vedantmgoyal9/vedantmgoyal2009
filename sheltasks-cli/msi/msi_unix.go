//go:build linux || darwin

/*
Copyright © 2023 Vedant
*/
package msi

/*
#cgo pkg-config: libmsi-1.0
#include <stdio.h>
#include <libmsi.h>
*/
import "C"

import (
	"fmt"
	"os"
	"regexp"
	"unsafe"
)

var _msiPropertyTable = make(map[string]string)

func GetProperty(propertyName, msiPath string) (string, error) {
	cMsiPath := C.CString(msiPath)
	defer C.free(unsafe.Pointer(cMsiPath))

	var gerr *C.GError

	var msiDb *C.LibmsiDatabase = C.libmsi_database_new(cMsiPath, C.LIBMSI_DB_FLAGS_READONLY, nil, &gerr)
	if msiDb == nil {
		return "", fmt.Errorf("error opening msi database: %v", C.GoString(gerr.message))
	}

	tableName := C.CString("Property")
	defer C.free(unsafe.Pointer(tableName))

	tmpFile, err := os.CreateTemp("/tmp/", "msitabledata")
	if err != nil {
		return "", fmt.Errorf("error creating temp file to store msi table data: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	cTmpFile := C.CString(tmpFile.Name())
	defer C.free(unsafe.Pointer(cTmpFile))
	C.freopen(cTmpFile, C.CString("w"), C.stdout)

	C.libmsi_database_export(msiDb, tableName, C.STDOUT_FILENO, &gerr)

	data, err := os.ReadFile(tmpFile.Name())
	if err != nil {
		return "", fmt.Errorf("error reading temp file which stores msi table data: %v", err)
	}

	for _, line := range regexp.MustCompile(`\r?\n`).Split(string(data)[:(len(data)-2)], -1) {
		lineData := regexp.MustCompile(`\s+`).Split(line, 2)
		_msiPropertyTable[lineData[0]] = lineData[1]
	}

	if val, ok := _msiPropertyTable[propertyName]; ok {
		return val, nil
	} else {
		return "", fmt.Errorf("property %s not found in Property table of msi database", propertyName)
	}
}
