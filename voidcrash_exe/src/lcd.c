// vim: noet ts=4 sw=4
#include <stdint.h>
#include "gd32vf103.h"

#include "lcd.h"

static void spi_config() {
	spi_parameter_struct spi_init_struct;
	/* deinitilize SPI and the parameters */
	OLED_CS_set();
	spi_struct_para_init(&spi_init_struct);

	/* SPI0 parameter config */
	spi_init_struct.trans_mode			 = SPI_TRANSMODE_FULLDUPLEX;
	spi_init_struct.device_mode			 = SPI_MASTER;
	spi_init_struct.frame_size			 = SPI_FRAMESIZE_8BIT;
	spi_init_struct.clock_polarity_phase = SPI_CK_PL_HIGH_PH_2EDGE;
	spi_init_struct.nss					 = SPI_NSS_SOFT;
	spi_init_struct.prescale			 = SPI_PSC_8;
	spi_init_struct.endian				 = SPI_ENDIAN_MSB;
	spi_init(SPI0, &spi_init_struct);

	spi_crc_polynomial_set(SPI0,7);
	spi_enable(SPI0);
}

static void lcd_write_bus(const uint8_t buf) {
	OLED_CS_clr();

	while (RESET == spi_i2s_flag_get(SPI0, SPI_FLAG_TBE)) {
		spi_i2s_data_transmit(SPI0, buf);
	}

	while (RESET == spi_i2s_flag_get(SPI0, SPI_FLAG_RBNE)) {
		spi_i2s_data_receive(SPI0);
	}

	OLED_CS_set();
}

static void lcd_write_char(const uint8_t buf) {
	OLED_DC_set();
	lcd_write_bus(buf);
}

static void lcd_write_int(const uint16_t buf) {
	OLED_DC_set();
	lcd_write_bus(buf>>8);
	lcd_write_bus(buf);
}

static void lcd_write_reg(const uint8_t buf) {
	OLED_DC_clr();
	lcd_write_bus(buf);
}

static void lcd_address_set(const uint16_t x1, const uint16_t y1,
							const uint16_t x2, const uint16_t y2) {
	if (USE_HORIZONTAL == 0) {
		lcd_write_reg(0x2a);
		lcd_write_int(x1+26);
		lcd_write_int(x2+26);
		lcd_write_reg(0x2b);
		lcd_write_int(y1+1);
		lcd_write_int(y2+1);
		lcd_write_reg(0x2c);
	} else if (USE_HORIZONTAL == 1) {
		lcd_write_reg(0x2a);
		lcd_write_int(x1+26);
		lcd_write_int(x2+26);
		lcd_write_reg(0x2b);
		lcd_write_int(y1+1);
		lcd_write_int(y2+1);
		lcd_write_reg(0x2c);
	} else if (USE_HORIZONTAL == 2) {
		lcd_write_reg(0x2a);
		lcd_write_int(x1+1);
		lcd_write_int(x2+1);
		lcd_write_reg(0x2b);
		lcd_write_int(y1+26);
		lcd_write_int(y2+26);
		lcd_write_reg(0x2c);
	} else {
		lcd_write_reg(0x2a);
		lcd_write_int(x1+1);
		lcd_write_int(x2+1);
		lcd_write_reg(0x2b);
		lcd_write_int(y1+26);
		lcd_write_int(y2+26);
		lcd_write_reg(0x2c);
	}
}


void lcd_init() {
	rcu_periph_clock_enable(RCU_GPIOB);

	rcu_periph_clock_enable(RCU_AF);
	rcu_periph_clock_enable(RCU_SPI0);
	/* SPI0 GPIO config: NSS/PA4, SCK/PA5, MOSI/PA7 */
    gpio_init(GPIOA, GPIO_MODE_AF_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_5 |GPIO_PIN_6| GPIO_PIN_7);
	gpio_init(GPIOB, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_2);

	spi_config();

	gpio_init(GPIOB, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_0 | GPIO_PIN_1);
	gpio_bit_reset(GPIOB, GPIO_PIN_0 | GPIO_PIN_1);

	OLED_RST_clr();
	delay_1ms(200);
	OLED_RST_set();
	delay_1ms(20);
	OLED_BLK_set();

	lcd_write_reg(0x11);	// turn off sleep mode
	delay_1ms(100);

	lcd_write_reg(0x21);	// display inversion mode

	lcd_write_reg(0xB1);	// Set the frame frequency of the full colors normal mode
						// Frame rate=fosc/((RTNA x 2 + 40) x (LINE + FPA + BPA +2))
						// fosc = 850kHz
	lcd_write_char(0x05);	// RTNA
	lcd_write_char(0x3A);	// FPA
	lcd_write_char(0x3A);	// BPA

	lcd_write_reg(0xB2);	// Set the frame frequency of the Idle mode
						// Frame rate=fosc/((RTNB x 2 + 40) x (LINE + FPB + BPB +2))
						// fosc = 850kHz
	lcd_write_char(0x05);	// RTNB
	lcd_write_char(0x3A);	// FPB
	lcd_write_char(0x3A);	// BPB

	lcd_write_reg(0xB3);	// Set the frame frequency of the Partial mode/ full colors
	lcd_write_char(0x05);  
	lcd_write_char(0x3A);
	lcd_write_char(0x3A);
	lcd_write_char(0x05);
	lcd_write_char(0x3A);
	lcd_write_char(0x3A);

	lcd_write_reg(0xB4);
	lcd_write_char(0x03);

	lcd_write_reg(0xC0);
	lcd_write_char(0x62);
	lcd_write_char(0x02);
	lcd_write_char(0x04);

	lcd_write_reg(0xC1);
	lcd_write_char(0xC0);

	lcd_write_reg(0xC2);
	lcd_write_char(0x0D);
	lcd_write_char(0x00);

	lcd_write_reg(0xC3);
	lcd_write_char(0x8D);
	lcd_write_char(0x6A);   

	lcd_write_reg(0xC4);
	lcd_write_char(0x8D); 
	lcd_write_char(0xEE); 

	lcd_write_reg(0xC5);  /*VCOM*/
	lcd_write_char(0x0E);

	lcd_write_reg(0xE0);
	lcd_write_char(0x10);
	lcd_write_char(0x0E);
	lcd_write_char(0x02);
	lcd_write_char(0x03);
	lcd_write_char(0x0E);
	lcd_write_char(0x07);
	lcd_write_char(0x02);
	lcd_write_char(0x07);
	lcd_write_char(0x0A);
	lcd_write_char(0x12);
	lcd_write_char(0x27);
	lcd_write_char(0x37);
	lcd_write_char(0x00);
	lcd_write_char(0x0D);
	lcd_write_char(0x0E);
	lcd_write_char(0x10);

	lcd_write_reg(0xE1);
	lcd_write_char(0x10);
	lcd_write_char(0x0E);
	lcd_write_char(0x03);
	lcd_write_char(0x03);
	lcd_write_char(0x0F);
	lcd_write_char(0x06);
	lcd_write_char(0x02);
	lcd_write_char(0x08);
	lcd_write_char(0x0A);
	lcd_write_char(0x13);
	lcd_write_char(0x26);
	lcd_write_char(0x36);
	lcd_write_char(0x00);
	lcd_write_char(0x0D);
	lcd_write_char(0x0E);
	lcd_write_char(0x10);

	lcd_write_reg(0x3A);	// define the format of RGB picture data
	lcd_write_char(0x05);	// 16-bit/pixel

	lcd_write_reg(0x36);
	if(USE_HORIZONTAL==0)lcd_write_char(0x08);
	else if(USE_HORIZONTAL==1)lcd_write_char(0xC8);
	else if(USE_HORIZONTAL==2)lcd_write_char(0x78);
	else lcd_write_char(0xA8);

	lcd_write_reg(0x29);	// Display On
}

void lcd_clear(const uint16_t buf) {
	uint16_t i = 0;
	uint16_t j = 0;
	lcd_address_set(0, 0, LCD_W-1, LCD_H-1);
	for (i=0; i<LCD_W; i++) {
		for (j=0; j<LCD_H; j++) {
			lcd_write_int(buf);
		}
	}
}
