#include "ac_rev_comp.h"
#include "commands.h"
#include "hal.h"
#include "math.h"
#include "defines.h"
#include "angle.h"

HAL_COMP(ac_rev);

HAL_PIN(in);
HAL_PIN(out);
HAL_PIN(in_d);
HAL_PIN(out_d);
HAL_PIN(rev);

static void rt_func(float period, void *ctx_ptr, hal_pin_inst_t *pin_ptr) {
  // struct ac_rev_ctx_t * ctx = (struct ac_rev_ctx_t *)ctx_ptr;
  struct ac_rev_pin_ctx_t *pins = (struct ac_rev_pin_ctx_t *)pin_ptr;

    float t;
    t = cosf(acosf(PIN(in)/M_PI*PIN(rev)))*M_PI;
    PIN(out) = t;
    
    
    //PIN(out)   = PIN(in);
    PIN(out_d) = PIN(in_d);


//  if(PIN(rev) > 0.0) {
//    PIN(out)   = minus(0, PIN(in));
//    PIN(out_d) = -PIN(in_d);
//  } else {
//    PIN(out)   = PIN(in);
//    PIN(out_d) = PIN(in_d);
//  }
}

hal_comp_t ac_rev_comp_struct = {
    .name      = "ac_rev",
    .nrt       = 0,
    .rt        = rt_func,
    .frt       = 0,
    .nrt_init  = 0,
    .rt_start  = 0,
    .frt_start = 0,
    .rt_stop   = 0,
    .frt_stop  = 0,
    .ctx_size  = 0,
    .pin_count = sizeof(struct ac_rev_pin_ctx_t) / sizeof(struct hal_pin_inst_t),
};
