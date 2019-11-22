// vim: noet ts=4 sw=4
#include "gd32vf103.h"

#include "lcd.h"
#include "systick.h"

void init() {
	rcu_periph_clock_enable(RCU_GPIOA);
	rcu_periph_clock_enable(RCU_GPIOC);
	rcu_periph_clock_enable(RCU_USART0);

	gpio_init(GPIOC, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_13);
	gpio_init(GPIOA, GPIO_MODE_OUT_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_1|GPIO_PIN_2);

	/* connect port to USARTx_Tx */
	gpio_init(GPIOA, GPIO_MODE_AF_PP, GPIO_OSPEED_50MHZ, GPIO_PIN_9);
	/* connect port to USARTx_Rx */
	gpio_init(GPIOA, GPIO_MODE_IN_FLOATING, GPIO_OSPEED_50MHZ, GPIO_PIN_10);

	/* UART stuff. */
	usart_deinit(USART0);
	usart_baudrate_set(USART0, 115200U);
	usart_word_length_set(USART0, USART_WL_8BIT);
	usart_stop_bit_set(USART0, USART_STB_1BIT);
	usart_parity_config(USART0, USART_PM_NONE);
	usart_hardware_flow_rts_config(USART0, USART_RTS_DISABLE);
	usart_hardware_flow_cts_config(USART0, USART_CTS_DISABLE);
	usart_receive_config(USART0, USART_RECEIVE_ENABLE);
	usart_transmit_config(USART0, USART_TRANSMIT_ENABLE);
	usart_enable(USART0);

	usart_interrupt_enable(USART0, USART_INT_RBNE);
}

int main() {
	init();
	//lcd_init();
	//lcd_clear(0xFFFF);

	//while (1) {
	//	LCD_ShowString(24,  0, (uint8_t *)("no card found!"), 0xF800);
	//	LCD_ShowString(24, 16, (uint8_t *)("no card found!"), 0xF800);
	//	LCD_ShowString(24, 32, (uint8_t *)("no card found!"), 0xF800);
	//	LCD_ShowString(24, 48, (uint8_t *)("no card found!"), 0xF800);
	//	LCD_ShowString(24, 64, (uint8_t *)("no card found!"), 0xF800);
	while (1) {
		GPIO_BOP(GPIOC) = GPIO_PIN_13;
		delay_1ms(500);
		GPIO_BC(GPIOC) = GPIO_PIN_13;
		delay_1ms(500);
	}
	//}
}
