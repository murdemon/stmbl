#include "spi.h"

#define SYSTICK_LOAD (SystemCoreClock/1000000U)
#define SYSTICK_DELAY_CALIB (SYSTICK_LOAD >> 1)

#define DELAY_US(us) \
    do { \
         uint32_t start = SysTick->VAL; \
         uint32_t ticks = (us * SYSTICK_LOAD)-SYSTICK_DELAY_CALIB;  \
         while((start - SysTick->VAL) < ticks); \
    } while (0)

void spi_gpio_setup(void)
{
 

     // Assuming PA13 and PA14 are SWD pins
     /*GPIO_InitTypeDef GPIO_InitStructure;
     RCC_APB2PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE); // Enable clock for GPIOA
     GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13 | GPIO_Pin_14;
     GPIO_InitStructure.GPIO_Mode = GPIO_OType_PP; // Push-pull output
     GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
     GPIO_Init(GPIOA, &GPIO_InitStructure);
    */

    GPIO_InitTypeDef gpio;

    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOD, ENABLE);
    RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOC, ENABLE);

    /* SPI GPIO Configuration --------------------------------------------------*/
    GPIO_PinAFConfig(GPIOB, GPIO_PinSource3, GPIO_AF_SPI1);
    GPIO_PinAFConfig(GPIOB, GPIO_PinSource4, GPIO_AF_SPI1);
    GPIO_PinAFConfig(GPIOB, GPIO_PinSource5, GPIO_AF_SPI1);

    /* SPI SCK pin configuration */
    gpio.GPIO_Pin   = GPIO_Pin_3;
    gpio.GPIO_Mode  = GPIO_Mode_AF;
    gpio.GPIO_Speed = GPIO_Speed_100MHz;
    gpio.GPIO_OType = GPIO_OType_PP;
    gpio.GPIO_PuPd  = GPIO_PuPd_UP;
    GPIO_Init(GPIOB, &gpio);

    /* SPI  MISO pin configuration */
    gpio.GPIO_Pin   = GPIO_Pin_4;
    gpio.GPIO_Mode  = GPIO_Mode_AF;
    gpio.GPIO_Speed = GPIO_Speed_100MHz;
    gpio.GPIO_OType = GPIO_OType_PP;
    gpio.GPIO_PuPd  = GPIO_PuPd_UP;
    GPIO_Init(GPIOB, &gpio);  

    /* SPI  MOSI pin configuration */
    gpio.GPIO_Pin   = GPIO_Pin_5;
    gpio.GPIO_Mode  = GPIO_Mode_AF;
    gpio.GPIO_Speed = GPIO_Speed_100MHz;
    gpio.GPIO_OType = GPIO_OType_PP;
    gpio.GPIO_PuPd  = GPIO_PuPd_UP;
    GPIO_Init(GPIOB, &gpio);

    /* CS */
    gpio.GPIO_Pin   = GPIO_Pin_4; 
    gpio.GPIO_Mode  = GPIO_Mode_OUT;
    gpio.GPIO_Speed = GPIO_Speed_100MHz;
    gpio.GPIO_OType = GPIO_OType_PP;
    gpio.GPIO_PuPd  = GPIO_PuPd_DOWN;
    GPIO_Init(GPIOC, &gpio);


    /*Spare SYNC1*/
    /*gpio.GPIO_Pin   = GPIO_Pin_14; 
    gpio.GPIO_Mode  = GPIO_Mode_IN;
    gpio.GPIO_Speed = GPIO_Speed_50MHz;
    gpio.GPIO_OType = GPIO_OType_PP;
    gpio.GPIO_PuPd  = GPIO_PuPd_NOPULL;
    GPIO_Init(GPIOA, &gpio);
    */
}

void spi_setup(void)
{
    spi_gpio_setup();
    
    SPI_InitTypeDef  spi;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI1, ENABLE);

    SPI_I2S_DeInit(SPI1);
    spi.SPI_Direction         = SPI_Direction_2Lines_FullDuplex;
    spi.SPI_DataSize          = SPI_DataSize_8b;
    spi.SPI_CPOL              = SPI_CPOL_Low;
    spi.SPI_CPHA              = SPI_CPHA_1Edge;
    spi.SPI_NSS               = SPI_NSS_Soft;
    spi.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;
    spi.SPI_FirstBit          = SPI_FirstBit_MSB;
    spi.SPI_CRCPolynomial     = 7;
    spi.SPI_Mode              = SPI_Mode_Master;
    SPI_Init(SPI1, &spi);

    while(SPI_I2S_GetFlagStatus(SPI1, SPI_I2S_FLAG_TXE) == RESET) { }

    /* Enable the SPI peripheral */
    SPI_Cmd(SPI1, ENABLE);
}

void spi_select (int8_t board)
{
    // Soft CSM
    #if SCS_ACTIVE_POLARITY == SCS_LOW
    GPIO_ResetBits(ESC_GPIOX_CS, ESC_GPIO_Pin_CS);
    #elif SCS_ACTIVE_POLARITY == SCS_HIGH
    GPIO_SetBits(ESC_GPIOX_CS, ESC_GPIO_Pin_CS);
    #endif
}

void spi_unselect (int8_t board)
{
    #if SCS_ACTIVE_POLARITY == SCS_LOW
	GPIO_SetBits(ESC_GPIOX_CS, ESC_GPIO_Pin_CS);
    #elif SCS_ACTIVE_POLARITY == SCS_HIGH
    GPIO_ResetBits(ESC_GPIOX_CS, ESC_GPIO_Pin_CS);
    #endif
}

inline static uint8_t spi_transfer(uint8_t byte)
{


    SPI_I2S_SendData(SPIX_ESC, byte);
  
    while ( SPI_I2S_GetFlagStatus(SPIX_ESC, SPI_I2S_FLAG_RXNE) == RESET) { }
    //while ( SPI_I2S_GetFlagStatus(SPIX_ESC, SPI_I2S_FLAG_BSY) == RESET) { }
    
    // TODO add timeout

    return SPI_I2S_ReceiveData(SPIX_ESC);
}

void spi_write (int8_t board, uint8_t *data, uint8_t size)
{
    for(int i = 0; i < size; ++i)
    {
        spi_transfer(data[i]);
    }
}

void spi_read (int8_t board, uint8_t *result, uint8_t size)
{
	for(int i = 0; i < size; ++i)
    {
        result[i] = spi_transfer(DUMMY_BYTE);
    }
}


void spi_bidirectionally_transfer (int8_t board, uint8_t *result, uint8_t *data, uint8_t size)
{
	for(int i = 0; i < size; ++i)
    {
        result[i] = spi_transfer(data[i]);
    }
}
