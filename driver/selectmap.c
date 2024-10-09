
#include <direct.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

/**********************************************************************
 * MARCO define
 **********************************************************************/
#define SM0_ADDR 0x000C0004U           // selectmap base addr

#ifdef __cplusplus
extern "C"
{
#endif
    /**********************************************************************
     * type define
     **********************************************************************/
    typedef union selectMap_t
    {
        struct
        {
            uint32_t config_en : 1;
            uint32_t boot_mode : 3;
            uint32_t read_write_n : 1;
            uint32_t program_n : 1;
            uint32_t rst_n : 1;
            uint32_t busy : 1;   // RO
            uint32_t init_n : 1; // RO
            uint32_t done : 1;   // RO
            uint32_t empty : 1;  // RO
            uint32_t : 5;        // RO
            uint32_t : 16;       // RO
        };
        uint32_t dword;
    } selectMap_t;

    /**********************************************************************
     * extern function declaration
     **********************************************************************/
    extern int read_reg(uint32_t addr, uint32_t *data);
    extern int write_reg(uint32_t addr, uint32_t data);

    /**********************************************************************
     * local function declaration
     **********************************************************************/
    void selemap_init(void);
    void selemap_deinit(void);

    /**********************************************************************
     * local variable define
     **********************************************************************/
    selectMap_t *selectmap_ctrl0 = (selectMap_t *)SM0_ADDR;

    /**********************************************************************
     * selectmap_ui.v
     **********************************************************************/
    void selemap_init(void)
    {
        // enable cclk
        selectmap_ctrl0->config_en = 1U;
        selectmap_ctrl0->program_n = 1U;
        selectmap_ctrl0->rst_n = 1U;
        selectmap_ctrl0->read_write_n = 1U;
        selectmap_ctrl0->boot_mode = 6U;
        udelay(1000);

        // assert program_n to reset fpga
        selectmap_ctrl0->program_n = 0U;
        selectmap_ctrl0->rst_n = 0U;
        selectmap_ctrl0->read_write_n = 0U;
        selectmap_ctrl0->config_en = 1U;
        udelay(1000);

        // deassert program_n to start config
        selectmap_ctrl0->program_n = 1U;
        selectmap_ctrl0->rst_n = 0U;
        selectmap_ctrl0->read_write_n = 0U;
        selectmap_ctrl0->config_en = 1U;
    }

    void selemap_deinit(void)
    {
        if (selectmap_ctrl0->done == 0U)
        {
            printf("\r\nconfig error\r\n");
        }

        // quit config
        selectmap_ctrl0->config_en = 0U;
        selectmap_ctrl0->program_n = 1U;
        selectmap_ctrl0->rst_n = 1U;
        selectmap_ctrl0->read_write_n = 1U;
        selectmap_ctrl0->boot_mode = 6U;
    }

#ifdef __cplusplus
}
#endif