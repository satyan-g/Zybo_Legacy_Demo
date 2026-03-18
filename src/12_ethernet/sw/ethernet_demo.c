/*
 * ethernet_demo.c — lwIP Echo Server for Zybo (bare-metal)
 *
 * Board gets IP via DHCP (falls back to static 192.168.1.10).
 * Listens on TCP port 7, echoes received data back to sender.
 * LED0 toggles on each received packet.
 *
 * Test: telnet <board-ip> 7   OR   nc <board-ip> 7
 */

#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"
#include "xil_cache.h"
#include "sleep.h"

#include "lwip/tcp.h"
#include "lwip/init.h"
#include "lwip/dhcp.h"
#include "lwip/timeouts.h"
#include "netif/xadapter.h"

/* Provide sys_now() for lwIP timers (bare-metal, NO_SYS=1)
 * Uses the ARM private timer via sleep counter */
#include "xil_io.h"
#define GLOBAL_TMR_BASE  0xF8F00200
#define GLOBAL_TMR_LOW   (GLOBAL_TMR_BASE + 0x00)
u32 sys_now(void)
{
    /* Global timer runs at CPU_freq/2 = 325 MHz on Zybo (650 MHz ARM) */
    static u32 last_raw = 0;
    static u32 ms_accum = 0;
    u32 raw = Xil_In32(GLOBAL_TMR_LOW);
    u32 delta = raw - last_raw;
    last_raw = raw;
    ms_accum += delta / 325000;  /* 325 MHz → ms */
    return ms_accum;
}

/* ------------------------------------------------------------------ */
/* Configuration                                                       */
/* ------------------------------------------------------------------ */
#define ECHO_PORT       7
#define LED_CHANNEL     1

/* Static IP fallback (used if DHCP fails after timeout) */
/* Static IP fallback — edit these for your network, or rely on DHCP */
#ifndef DEFAULT_IP_0
#define DEFAULT_IP_0  192
#define DEFAULT_IP_1  168
#define DEFAULT_IP_2  1
#define DEFAULT_IP_3  10
#define DEFAULT_GW_3  1    /* gateway = x.x.x.1 */
#endif

/* DHCP timeout in seconds before falling back to static IP */
#define DHCP_TIMEOUT_S  10

/* ------------------------------------------------------------------ */
/* Globals                                                             */
/* ------------------------------------------------------------------ */
static struct netif netif;
static XGpio gpio;
static u32 led_state = 0;

/* ------------------------------------------------------------------ */
/* LED helpers                                                         */
/* ------------------------------------------------------------------ */
static void led_init(void)
{
    XGpio_Initialize(&gpio, XPAR_AXI_GPIO_0_BASEADDR);
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x0); /* all outputs */
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, 0x0);
}

static void led_toggle(u32 mask)
{
    led_state ^= mask;
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_state);
}

static void led_set(u32 val)
{
    led_state = val;
    XGpio_DiscreteWrite(&gpio, LED_CHANNEL, led_state);
}

/* ------------------------------------------------------------------ */
/* lwIP TCP echo callbacks                                             */
/* ------------------------------------------------------------------ */

/* Called when data is received on an accepted connection */
static err_t echo_recv_cb(void *arg, struct tcp_pcb *pcb, struct pbuf *p,
                           err_t err)
{
    (void)arg;

    if (p == NULL) {
        /* Remote end closed connection */
        xil_printf("Connection closed by remote host\r\n");
        tcp_close(pcb);
        return ERR_OK;
    }

    if (err != ERR_OK) {
        pbuf_free(p);
        return err;
    }

    /* Acknowledge received data */
    tcp_recved(pcb, p->tot_len);

    /* Echo it back */
    err_t wr_err = tcp_write(pcb, p->payload, p->tot_len, TCP_WRITE_FLAG_COPY);
    if (wr_err != ERR_OK) {
        xil_printf("tcp_write error: %d\r\n", wr_err);
    } else {
        tcp_output(pcb);
    }

    /* Toggle LED0 on each received packet */
    led_toggle(0x1);

    pbuf_free(p);
    return ERR_OK;
}

/* Called when a connection error occurs */
static void echo_err_cb(void *arg, err_t err)
{
    (void)arg;
    xil_printf("TCP error: %d\r\n", err);
    /* Turn off activity LED on error */
    led_set(led_state & ~0x1);
}

/* Called when a new connection is accepted */
static err_t echo_accept_cb(void *arg, struct tcp_pcb *newpcb, err_t err)
{
    (void)arg;
    (void)err;

    xil_printf("New connection accepted\r\n");

    tcp_recv(newpcb, echo_recv_cb);
    tcp_err(newpcb, echo_err_cb);

    /* Light LED1 to indicate active connection */
    led_set(led_state | 0x2);

    return ERR_OK;
}

/* Start the echo server: bind to port 7, listen */
static int echo_server_start(void)
{
    struct tcp_pcb *pcb;
    err_t err;

    pcb = tcp_new();
    if (pcb == NULL) {
        xil_printf("ERROR: tcp_new failed\r\n");
        return -1;
    }

    err = tcp_bind(pcb, IP_ADDR_ANY, ECHO_PORT);
    if (err != ERR_OK) {
        xil_printf("ERROR: tcp_bind failed: %d\r\n", err);
        return -1;
    }

    pcb = tcp_listen(pcb);
    if (pcb == NULL) {
        xil_printf("ERROR: tcp_listen failed\r\n");
        return -1;
    }

    tcp_accept(pcb, echo_accept_cb);

    xil_printf("Echo server listening on port %d\r\n", ECHO_PORT);
    return 0;
}

/* ------------------------------------------------------------------ */
/* Network setup                                                       */
/* ------------------------------------------------------------------ */
static void print_ip(const char *label, ip_addr_t *addr)
{
    xil_printf("%s: %d.%d.%d.%d\r\n", label,
        ip4_addr1(addr), ip4_addr2(addr),
        ip4_addr3(addr), ip4_addr4(addr));
}

static void setup_network(void)
{
    ip_addr_t ipaddr, netmask, gw;
    unsigned char mac[] = { 0x00, 0x0a, 0x35, 0x00, 0x01, 0x02 };

    xil_printf("\r\n--- Network Configuration ---\r\n");

    /* Start with zeros — DHCP will fill in */
    IP4_ADDR(&ipaddr,  0, 0, 0, 0);
    IP4_ADDR(&netmask, 0, 0, 0, 0);
    IP4_ADDR(&gw,      0, 0, 0, 0);

    /* Initialize lwIP */
    lwip_init();

    /* Add network interface */
    if (!xemac_add(&netif, &ipaddr, &netmask, &gw, mac,
                   XPAR_XEMACPS_0_BASEADDR)) {
        xil_printf("ERROR: xemac_add failed\r\n");
        return;
    }
    netif_set_default(&netif);
    netif_set_up(&netif);

    /* Try DHCP first */
    xil_printf("Starting DHCP...\r\n");
    dhcp_start(&netif);

    /* LED2 on = waiting for DHCP */
    led_set(led_state | 0x4);

    /* Poll for DHCP completion — 1ms per tick, TIMEOUT_S seconds total */
    int dhcp_ticks = DHCP_TIMEOUT_S * 1000;
    while (dhcp_ticks > 0) {
        xemacif_input(&netif);
        sys_check_timeouts();

        if (netif.ip_addr.addr != 0) {
            xil_printf("DHCP successful!\r\n");
            /* LED2 off, LED3 on = got IP */
            led_set((led_state & ~0x4) | 0x8);
            print_ip("  IP address ", &netif.ip_addr);
            print_ip("  Netmask    ", &netif.netmask);
            print_ip("  Gateway    ", &netif.gw);
            return;
        }

        usleep(1000);  /* 1 ms */
        dhcp_ticks--;
    }

    /* DHCP failed — use static IP */
    xil_printf("DHCP timed out, using static IP\r\n");
    dhcp_stop(&netif);

    IP4_ADDR(&ipaddr,  DEFAULT_IP_0, DEFAULT_IP_1, DEFAULT_IP_2, DEFAULT_IP_3);
    IP4_ADDR(&netmask, 255, 255, 255, 0);
    IP4_ADDR(&gw,      DEFAULT_IP_0, DEFAULT_IP_1, DEFAULT_IP_2, DEFAULT_GW_3);
    netif_set_addr(&netif, &ipaddr, &netmask, &gw);

    /* LED2 off, LED3 on = got IP (static) */
    led_set((led_state & ~0x4) | 0x8);

    print_ip("  IP address ", &netif.ip_addr);
    print_ip("  Netmask    ", &netif.netmask);
    print_ip("  Gateway    ", &netif.gw);
}

/* ------------------------------------------------------------------ */
/* Main                                                                */
/* ------------------------------------------------------------------ */
int main(void)
{
    /* Enable caches for performance */
    Xil_ICacheEnable();
    Xil_DCacheEnable();

    xil_printf("\r\n");
    xil_printf("============================================\r\n");
    xil_printf(" 12_ethernet — lwIP Echo Server\r\n");
    xil_printf(" Original Zybo (GEM0 on MIO 16..27)\r\n");
    xil_printf("============================================\r\n");

    /* Initialize LEDs */
    led_init();

    /* LED0 on briefly = board alive */
    led_set(0x1);
    for (volatile int i = 0; i < 5000000; i++)
        ;
    led_set(0x0);

    /* Setup network interface (DHCP or static fallback) */
    setup_network();

    /* Start echo server on port 7 */
    if (echo_server_start() != 0) {
        xil_printf("ERROR: Failed to start echo server\r\n");
        led_set(0xF); /* all LEDs on = error */
        while (1)
            ;
    }

    xil_printf("\r\nReady! Connect with: telnet <ip> 7\r\n");
    xil_printf("Type text and it will be echoed back.\r\n\r\n");

    /* Main loop: pump lwIP */
    while (1) {
        xemacif_input(&netif);
        sys_check_timeouts();
    }

    /* Never reached */
    Xil_DCacheDisable();
    Xil_ICacheDisable();
    return 0;
}
