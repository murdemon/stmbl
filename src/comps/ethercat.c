#include "ethercat_comp.h"
/*
* This file is part of the stmbl project.
*
* Copyright (C) 2013 Rene Hopf <renehopf@mac.com>
* Copyright (C) 2015 Ian McMahon <facetious.ian@gmail.com>
* Copyright (C) 2013 Nico Stute <crinq@crinq.de>
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "commands.h"
#include "hal.h"
#include "math.h"
#include "defines.h"
#include "stm32f4xx_conf.h"
#include "hw/hw.h"
#include "crc8.h"
#include "setup.h"
#include <string.h>

#include "delay.h"
#include "usart.h"

#include "esc.h"
#include "ecat_slv.h"
#include "ecatapp.h"
#include "utypes.h"
#include "cia402device.h"


HAL_COMP(ethercat);

// pins
HAL_PIN(error);
HAL_PIN(crc_error);  //counts crc errors, is never reset
HAL_PIN(connected);  //connection status TODO: not stable during startup, needs link to pd
HAL_PIN(timeout);    // 20khz / 1khz * 2 reads = 40

HAL_PIN(pos_cmd);
HAL_PIN(pos_cmd_d);
HAL_PIN(pos_fb);
HAL_PIN(vel_fb);
HAL_PIN(current);
HAL_PIN(scale);

HAL_PIN(clock_scale);
HAL_PIN(available);
HAL_PIN(phase);

HAL_PIN(in0);
HAL_PIN(in1);
HAL_PIN(in2);
HAL_PIN(in3);
HAL_PIN(fault);

HAL_PIN(out0);
HAL_PIN(out1);
HAL_PIN(out2);
HAL_PIN(out3);
HAL_PIN(enable);
HAL_PIN(index_clear);
HAL_PIN(index_out);
HAL_PIN(pos_advance);

//TODO: move to ctx
struct ethercat_ctx_t {
  uint32_t phase;
};

extern uint32_t timeout;

#pragma pack(push, 1)

//global name:scale addr:0x12c size:32 dir:0x80
#define scale_address 300


#pragma pack(pop)

extern _Objects    Obj;

//TODO:

static void hw_init(void *ctx_ptr, hal_pin_inst_t *pin_ptr) {
  struct ethercat_pin_ctx_t *pins = (struct ethercat_pin_ctx_t *)pin_ptr;

  delay_init();
  ecatapp_init();

  PIN(timeout) = 100.0;  // 20khz / 1khz * 2 reads = 40
  PIN(clock_scale) = 1.0;
  PIN(phase)       = 0;
}


static void frt_func(float period, void *ctx_ptr, hal_pin_inst_t *pin_ptr) {
  struct ethercat_pin_ctx_t *pins = (struct ethercat_pin_ctx_t *)pin_ptr;


  ecatapp_loop();
  

//  Obj.Position_actual = PIN(pos_fb);
  Obj.Position_actual = Obj.Target_position;
  PIN(pos_cmd) = Obj.Target_position;
  PIN(enable) = (Obj.Control_Word & CIA402_CONTROLWORD_ENABLE_OPERATION);

  if(timeout > PIN(timeout)) {  //TODO: clamping
    PIN(connected) = 0;
    PIN(error)     = 1;
    PIN(pos_cmd)   = 0;
    PIN(pos_cmd_d) = 0;
    PIN(out0)      = 0;
    PIN(out1)      = 0;
    PIN(out2)      = 0;
    PIN(out3)      = 0;
    PIN(enable)    = 0;
  } else {
    PIN(connected) = 1;
    PIN(error)     = 0;
  }

  timeout++;

}


static void nrt(void *ctx_ptr, hal_pin_inst_t *pin_ptr) {
  //struct idpmsm_ctx_t * ctx = (struct idpmsm_ctx_t *)ctx_ptr;
  struct ethercat_pin_ctx_t *pins = (struct ethercat_pin_ctx_t *)pin_ptr;

  printf("Initilize Ethercat\n");

}

const hal_comp_t ethercat_comp_struct = {
    .name      = "ethercat",
    .nrt       = 0,//nrt,
    .rt        = 0,
    .frt       = frt_func,
    .nrt_init  = 0,
    .hw_init   = hw_init,
    .rt_start  = 0,
    .frt_start = 0,
    .rt_stop   = 0,
    .frt_stop  = 0,
    .ctx_size  = sizeof(struct ethercat_ctx_t),
    .pin_count = sizeof(struct ethercat_pin_ctx_t) / sizeof(struct hal_pin_inst_t),
};
