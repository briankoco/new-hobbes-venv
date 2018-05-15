/*
 * Copyright (c) 2010, Jack Lange <jacklange@cs.pitt.edu>
 * All rights reserved.
 *
 * This is free software.  You are permitted to use,
 * redistribute, and modify it as specified in the file "V3VEE_LICENSE".
 */


#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h> 
#include <sys/ioctl.h> 
#include <sys/stat.h> 
#include <sys/types.h> 
#include <unistd.h> 
#include <string.h>
 
#include "v3vee.h"
#include "v3_ioctl.h"

int main(int argc, char* argv[]) {
    char * filename = argv[1];

    if (argc <= 1) {
	printf("usage: v3_launch <vm-device>\n");
	return -1;
    }

    printf("Launching VM (%s)\n", filename);

    v3_launch_vm(get_vm_id_from_path(filename));

    return 0; 
} 


