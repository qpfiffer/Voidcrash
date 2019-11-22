#pragma once
#include <stdlib.h>

#include "gd32vf103_gpio.h"
#include "systick.h"

#define USE_HORIZONTAL 2  //设置横屏或者竖屏显示 0或1为竖屏 2或3为横屏
#define HAS_BLK_CNTL    0

#if USE_HORIZONTAL==0||USE_HORIZONTAL==1
#define LCD_W 80
#define LCD_H 160
#else
#define LCD_W 160
#define LCD_H 80
#endif

typedef unsigned char u8;
typedef unsigned int u16;
typedef unsigned long u32;

// #define LED_ON gpio_bit_reset(GPIOC,GPIO_PIN_13)
// #define LED_OFF gpio_bit_set(GPIOC,GPIO_PIN_13)

#define LED_ON
#define LED_OFF

#define SPI0_CFG 1  //hardware spi

#define FRAME_SIZE  25600

#define OLED_SCLK_Clr()
#define OLED_SCLK_Set()

#define OLED_SDIN_Clr()
#define OLED_SDIN_Set()

#define OLED_CS_clr() gpio_bit_reset(GPIOB,GPIO_PIN_2)     //CS PB2
#define OLED_CS_set() gpio_bit_set(GPIOB,GPIO_PIN_2)

#define OLED_RST_clr() gpio_bit_reset(GPIOB,GPIO_PIN_1)     //RES PB1
#define OLED_RST_set() gpio_bit_set(GPIOB,GPIO_PIN_1)

#define OLED_DC_clr() gpio_bit_reset(GPIOB,GPIO_PIN_0)      //DC PB0
#define OLED_DC_set() gpio_bit_set(GPIOB,GPIO_PIN_0)


#if     HAS_BLK_CNTL
#define OLED_BLK_clr()  gpio_bit_reset(GPIOA,GPIO_PIN_5)//BLK
#define OLED_BLK_set()  gpio_bit_set(GPIOA,GPIO_PIN_5)
#else
#define OLED_BLK_clr()
#define OLED_BLK_set()
#endif

#define OLED_CMD  0	//写命令
#define OLED_DATA 1	//写数据

extern  u16 BACK_COLOR;   //背景色
extern unsigned char image[12800];

void LCD_Writ_Bus(u8 dat);
void LCD_WR_DATA8(u8 dat);
void LCD_WR_DATA(u16 dat);
void LCD_WR_REG(u8 dat);
void LCD_Address_Set(u16 x1,u16 y1,u16 x2,u16 y2);
void Lcd_Init(void);
void LCD_Clear(u16 Color);
void LCD_ShowChinese(u16 x,u16 y,u8 index,u8 size,u16 color);
void LCD_DrawPoint(uint16_t x,uint16_t y,uint16_t color);
void LCD_DrawPoint_big(u16 x,u16 y,u16 color);
void LCD_Fill(u16 xsta,u16 ysta,u16 xend,u16 yend,u16 color);
void LCD_DrawLine(u16 x1,u16 y1,u16 x2,u16 y2,u16 color);
void LCD_DrawRectangle(u16 x1, u16 y1, u16 x2, u16 y2,u16 color);
void Draw_Circle(u16 x0,u16 y0,u8 r,u16 color);
void LCD_ShowChar(uint16_t x,uint16_t y,uint8_t num,uint8_t mode,uint16_t color);
void LCD_ShowString(uint16_t x,uint16_t y,const uint8_t *p,uint16_t color);
u32 mypow(u8 m,u8 n);
void LCD_ShowNum(u16 x,u16 y,u16 num,u8 len,u16 color);
void LCD_ShowNum1(u16 x,u16 y,float num,u8 len,u16 color);
void LCD_ShowPicture(u16 x1,u16 y1,u16 x2,u16 y2);
void LCD_ShowLogo(void);

void lcd_clear(const uint16_t buf);
void lcd_init();
