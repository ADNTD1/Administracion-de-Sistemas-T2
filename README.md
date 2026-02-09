\# Práctica – Servidor DHCP Automatizado  

\## Linux (NixOS) y Windows Server 2022



\## Descripción

En esta práctica se implementó una solución automatizada para instalar, configurar y monitorear un servidor DHCP en entornos Linux (NixOS) y Windows Server 2022.  

El objetivo es gestionar el direccionamiento IP dinámico de una red interna y validar que los clientes reciban correctamente los parámetros de red.



---



\## Topología de Red



\*\*Red interna:\*\* 192.168.100.0/24  

\*\*Gateway:\*\* 192.168.100.1  



\### Equipos

\- \*\*Srv-Linux-Sistemas\*\*

&nbsp; - SO: NixOS

&nbsp; - Servicio DHCP: dnsmasq

&nbsp; - IP: 192.168.100.3



\- \*\*Srv-Win-Sistemas\*\*

&nbsp; - SO: Windows Server 2022

&nbsp; - Servicio DHCP: Rol DHCP de Windows

&nbsp; - IP: 192.168.100.2



\- \*\*Cliente\*\*

&nbsp; - IP asignada por DHCP: 192.168.100.61



---



\## Implementación en Linux (NixOS)



\- Se utilizó `dnsmasq` como servidor DHCP.

\- La configuración se realizó de forma declarativa.

\- Se desarrolló un script Bash que:

&nbsp; - Solicita parámetros de red.

&nbsp; - Aplica la configuración DHCP.

&nbsp; - Verifica el estado del servicio.



\### Comandos principales

```bash

sudo nixos-rebuild switch

systemctl status dnsmasq

journalctl -u dnsmasq | grep DHCP



