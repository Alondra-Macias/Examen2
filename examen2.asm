ORG 0000H
JMP INIT

ORG 0003H 
JMP EXT0

ORG 000BH	
JMP TIM0

ORG 0013H 
JMP EXT1

ORG 002BH
CLR TF2
JMP TIM2


/*RENOMBRAMIENTOS*/
RS EQU P3.5
RW	EQU P3.6
E	EQU	P3.7
DBUS EQU P2
KEY EQU P0
ALT EQU P3.4
	
/*DIRECCIONES TIMER 2*/
T2CON EQU 00C8H
RCAP2L EQU 00CAH
RCAP2H EQU 00CBH
TL2 EQU 00CCH
TH2 EQU 00CDH
TF2 EQU 00CFH
TR2 EQU 0CAH
	
/*VARIABLES*/
WAIT50 EQU 70H		;BANDERA 
AAUX EQU 42H		;AUXILIAR PARA ALMACENAR A
AAUX_2 EQU 44H		;AUXILIAR 2 PARA ALMACENAR A
CUENTA20 EQU 4AH
CUENTA5 EQU 4BH

/* VARIABLES EXAMEN 2*/
PRECIO EQU 10H
TANQUEH EQU 11H
TANQUEL EQU 12H
CLIENT_CEN EQU 13H
CLIENT_DEC EQU 14H
CLIENT_UNI EQU 15H
NO_DATO EQU 16H
GETTING_DINERO EQU 48H
LITROS EQU 18H
SIN_DINERO EQU 49H
ESTADO_DESPACHANDO EQU 4AH
SIN_GAS EQU 4BH
PRECIO_CEN EQU 20H
PRECIO_DEC EQU 21H
PRECIO_UNI EQU 22H
TOTAL_CEN EQU 23H
TOTAL_DEC EQU 24H
TOTAL_UNI EQU 25H
LITROS_CEN EQU 26H
LITROS_DEC EQU 27H
LITROS_UNI EQU 28H





INIT:
	MOV SP, #50H
	
	MOV IE, #10100111B
	MOV IP, #00000010B
	MOV TCON, #00000101B
	MOV SCON, #01000010B
	MOV TMOD, #00100010B
	MOV TH0, #-250
	MOV TL0, #-250	
	MOV TH1, #(-3)
	MOV TL1, #(-3)
	
	MOV RCAP2H, #HIGH(-240); 
	MOV RCAP2L, #LOW(-240)
	MOV TH2, #HIGH(-25000)
	MOV TL2, #LOW(-25000)
	MOV T2CON, #00000000B	

	MOV DPTR, #1000H
	ACALL DELAY_50MS		
	
	SETB E
	CLR RS
	CLR RW
	
	MOV LITROS, #00H
	MOV PRECIO, #(12)
	
	MOV TANQUEH, #HIGH(50000)
	MOV TANQUEL, #LOW(50000)
	CLR SIN_GAS
	
	MOV CLIENT_CEN, #00H
	MOV CLIENT_DEC, #00H
	MOV CLIENT_UNI, #00H
	
	MOV LITROS_CEN, #00H
	MOV LITROS_DEC, #00H
	MOV LITROS_UNI, #00H
	
	MOV PRECIO_CEN, #00H
	MOV PRECIO_DEC, #01H
	MOV PRECIO_UNI, #02H
	
	MOV TOTAL_CEN, #00H
	MOV TOTAL_DEC, #00H
	MOV TOTAL_UNI, #00H
	
	ACALL INIT_DISPLAY	
	
	ACALL GET_DINERO	
		
	
	JMP $



TIM2: ;INTERRUPCION DEL TIMER PARA DESPACHAR LA GASOLINA	
	INC CUENTA5
	MOV A, CUENTA5
	CJNE A, #(5), FIN_TIM2
	
	ACALL CHECK_GAS
	ACALL CHECK_DINERO
	
	JB SIN_GAS, STOP
	JNB SIN_DINERO, DESPACHA
	STOP:
	CLR TR2
	JMP FIN_TIM2
	
	DESPACHA:
	ACALL DESPACHA_LITRO
	
	FIN_TIM2:
	RETI

TIM0: ;INTERRUPCION PARA DELAY
	INC CUENTA20
	MOV A, CUENTA20
	CJNE A, #(20), FIN_TIM0
	CLR WAIT50	
	MOV CUENTA20, #00H
	
	FIN_TIM0:
	RETI


EXT1: ;INTERRUPCION PARA TECLADO MATRICIAL	 
	MOV AAUX, A 
	MOV A, KEY			

	
	JNB GETTING_DINERO,	COMP_D 
 	CLR GETTING_DINERO
	
	COMP_D:
	CJNE A, #0DH, COMP_F
	SETB TR2
	JMP FIN_EXT1

	COMP_F:
	CJNE A, #0FH, FIN_EXT1
	CLR TR2
	JMP FIN_EXT1
	
	FIN_EXT1:
	MOV A, AAUX
	RETI

EXT0: ;INTERRUPCION PARA ENVIAR POR SERIAL	
	ACALL SEND_ALL
	
	RETI
	

/*SUBRUTINAS*/
DELAY_50MS:
	
	SETB TR0
	SETB WAIT50	
	
	JB WAIT50, $
		
	CLR TR0
	RET


INIT_DISPLAY: ;PREPARA EL LCD POR PRIMERA VEZ Y ESCRIBE LOS IDS Y DIGITOS INICIALES PARA EL DINERO DEL CLIENTE, PRECIO DE LA GAS, EL TOTAL Y LOS LITROS DESP.
	MOV DBUS, #38H
	ACALL EXECUTE_E
	
	MOV DBUS, #38H
	ACALL EXECUTE_E
	
	MOV DBUS, #01H
	ACALL EXECUTE_E
	
	MOV DBUS, #0FH
	ACALL EXECUTE_E	
	
	ACALL ESCRIBE_VARIABLES
	
	RET

ESCRIBE_VARIABLES:
	MOV DBUS,#'V'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#':'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#'$'
	ACALL ESCRIBE_DATO
	
	MOV A, CLIENT_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, CLIENT_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, CLIENT_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV DBUS, #88H
	ACALL EXECUTE_E
	
	MOV DBUS,#'L'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#':'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#'$'
	ACALL ESCRIBE_DATO
	
	MOV A, PRECIO_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, PRECIO_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, PRECIO_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV DBUS, #0C0H
	ACALL EXECUTE_E
	
	MOV DBUS, #'T'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#':'
	ACALL ESCRIBE_DATO
	
	MOV DBUS, #'$'
	ACALL ESCRIBE_DATO
	
	MOV A, TOTAL_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, TOTAL_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, TOTAL_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
		
	MOV DBUS, #0C8H
	ACALL EXECUTE_E
	
	MOV DBUS,#'D'
	ACALL ESCRIBE_DATO
	
	MOV DBUS,#':'
	ACALL ESCRIBE_DATO
	
	MOV A, LITROS_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, LITROS_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, LITROS_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV DBUS, #083H
	ACALL EXECUTE_E
	RET

EXECUTE_E:
	CPL E	
	CPL E
	ACALL DELAY_50MS
	RET

ESCRIBE_DATO:
	SETB RS
	ACALL EXECUTE_E
	CLR RS	
	RET

HEX_ASCII: 
	MOVC A, @A + DPTR
	RET


BORRAR_PANTALLA:
	MOV DBUS, #01H
	ACALL EXECUTE_E
	RET

	
GET_DINERO: ;ESPERA UNA TECLA DEL 0 AL 9 QUE INDIQUE EL DINERO DEL CLIENTE, GUARDA ESE NUMERO MULTIPLICADO POR 100 EN CLIENT_CEN Y LO MUESTRA EN EL LCD
		
	SETB GETTING_DINERO
	CLR SIN_DINERO
	
	JB GETTING_DINERO, $
		
	MOV CLIENT_CEN, KEY
	MOV A, KEY
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
		
	MOV CLIENT_DEC, #00H
	MOV CLIENT_UNI, #00H
	
	MOV DBUS, #30H
	ACALL ESCRIBE_DATO
	ACALL ESCRIBE_DATO

	FIN_GET_DINERO:
	CLR GETTING_DINERO
	RET

CHECK_DINERO: ;VERIFICA SI EL DINERO DEL CLIENTE (UNI, DEC Y CEN) ES IGUAL A 0 E INDICA SI EL CLIENTE YA NO TIENE DINERO CON LA BANDERA SIN_DINERO
	MOV A, CLIENT_UNI
	CJNE A, #00H, FIN_CHECK_DINERO
	MOV A, CLIENT_DEC
	CJNE A, #00H, FIN_CHECK_DINERO
	MOV A, CLIENT_CEN
	CJNE A, #00H, FIN_CHECK_DINERO
	SETB SIN_DINERO
	
	FIN_CHECK_DINERO:
	RET

RESTA_DINERO: ;RESTA 1 AL DINERO DEL CLIENTE (UNI, DEC Y CEN) Y VERIFICA SI UN DÍGITO SE VUELVE NEGATIVO PARA PONERLO EN 9 Y RESTARLE UNO AL SIGUIENTE DIGITO
	MOV AAUX, A
	
	ACALL CHECK_DINERO
	JB SIN_DINERO,FIN_RESTA_DINERO
	
	UNIDADES:
		DEC CLIENT_UNI
		MOV A, CLIENT_UNI
		CJNE A, #0FFH, FIN_RESTA_DINERO
		MOV CLIENT_UNI, #09H
	
	DECENAS:
		DEC CLIENT_DEC
		MOV A, CLIENT_DEC
		CJNE A, #0FFH, FIN_RESTA_DINERO
		MOV CLIENT_DEC, #09H
	
	CENTENAS:
		DEC CLIENT_CEN
		MOV A, CLIENT_CEN
		CJNE A, #0FFH, FIN_RESTA_DINERO
		MOV CLIENT_CEN, #09H
		
	FIN_RESTA_DINERO:
	MOV A, AAUX
	RET

CHECK_GAS: ;VERIFICA SI LA PARTE BAJA Y ALTA DEL TANQUE SON 0, EN ESE CASO SE INDICA QUE YA NO HAY GAS EN LA BANDERA SIN_GAS
	MOV A, TANQUEL
	CJNE A, #00H, FIN_CHECK_GAS
	MOV A, TANQUEH
	CJNE A, #00H, FIN_CHECK_GAS
	SETB SIN_GAS
	FIN_CHECK_GAS:
	RET

RESTA_LITRO: ;QUITA UN LITRO DEL TANQUE, SI LA PARTE BAJA SE VUELVE MENOR QUE 0, RESTA 1 A LA PARTE ALTA 
	MOV AAUX, A	
	
	ACALL CHECK_GAS
	JB SIN_GAS, FIN_RESTA_LITRO
	
	BAJA:
	DEC TANQUEL
	MOV A, TANQUEL
	CJNE A, #0FFH, FIN_RESTA_LITRO
	
	
	ALTA:
	DEC TANQUEH
	MOV A, TANQUEH
	CJNE A, #0FFH, FIN_RESTA_LITRO
	MOV TANQUEH, #HIGH(0)
	MOV TANQUEL, #LOW(0)

	FIN_RESTA_LITRO:
	MOV A, AAUX
	RET
	
	
DESPACHA_LITRO: ;RESTA EL COSTO UN LITRO AL CLIENTE Y LO SUMA AL TOTAL, AL FINAL HACE REFRESH DEL TOTAL Y LOS LITROS DESPACHADOS
	
	MOV A, #00H	

	COBRA_LITRO:
		CJNE A, PRECIO, OPERACION
		JMP ADD_TOTAL
		OPERACION:
		INC A
		ACALL RESTA_DINERO
		JB SIN_DINERO, FIN_DESPACHA_LITRO
		JMP COBRA_LITRO
	
	ADD_TOTAL:
	MOV A, #00H
	
	SUMA_TOTAL:
		CJNE A, PRECIO, OPERACION2
		JMP HANDLE_LITRO
		OPERACION2:
		INC A
		ACALL INCREMENTA_TOTAL		
		JMP SUMA_TOTAL
	
	HANDLE_LITRO:
		ACALL RESTA_LITRO 	;DEL TANQUE
		ACALL INCREMENTA_LITRO ;DE LO QUE DESPACHAS
	
	
	FIN_DESPACHA_LITRO:
	ACALL REFRESH_LITROS
	ACALL REFRESH_TOTAL
	RET
	
INCREMENTA_LITRO: ;LE SUMA 1 A LOS LITROS (DESPACHADOS) Y HACE LAS COMPARACIONES QUE VERIFICAN SI UNI, DEC O CEN SE PASAN DE 9 		
	MOV AAUX_2, A
	
	INC LITROS_UNI
	MOV A, LITROS_UNI
	CJNE A, #0AH, FIN_INCREMENTA_LITRO
	MOV LITROS_UNI, #00H
	
	INC LITROS_DEC
	MOV A, LITROS_DEC
	CJNE A, #0AH, FIN_INCREMENTA_LITRO
	MOV LITROS_DEC, #00H
	
	INC LITROS_CEN
	MOV A, LITROS_CEN
	CJNE A, #0AH, FIN_INCREMENTA_LITRO
	MOV LITROS_CEN, #00H
		
	
	FIN_INCREMENTA_LITRO:
	MOV A, AAUX_2
	RET

REFRESH_LITROS: ;REFRESCA LOS LITROS DESPACHADOS EN LA PANTALLA VOLVIENDO A ESCRIBIR LOS LITROS (UNI, DEC Y CEN) EN LA POSICION QUE FUERON ESCRITOS
	
	MOV DBUS, #0CAH
	ACALL EXECUTE_E
	
	MOV A, LITROS_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, LITROS_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, LITROS_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	RET

INCREMENTA_TOTAL: ;LE SUMA 1 AL TOTAL Y HACE LAS COMPARACIONES QUE VERIFICAN SI UNI, DEC O CEN SE PASAN DE 9 	
	MOV AAUX_2, A
	
	INC TOTAL_UNI
	MOV A, TOTAL_UNI
	CJNE A, #0AH, FIN_INCREMENTA_TOTAL
	MOV TOTAL_UNI, #00H
	
	INC TOTAL_DEC
	MOV A, TOTAL_DEC
	CJNE A, #0AH, FIN_INCREMENTA_TOTAL
	MOV TOTAL_DEC, #00H
	
	INC TOTAL_CEN
	MOV A, TOTAL_CEN
	CJNE A, #0AH, FIN_INCREMENTA_TOTAL
	MOV TOTAL_CEN, #00H
		
	
	FIN_INCREMENTA_TOTAL:
	MOV A, AAUX_2
	RET

REFRESH_TOTAL: ;REFRESCA EL TOTAL A PAGAR EN LA PANTALLA VOLVIENDO A ESCRIBIR EL TOTAL (UNI, DEC Y CEN) EN LA DIRECCION QUE FUERON ESCRITOS
	
	MOV DBUS, #0C3H
	ACALL EXECUTE_E
	
	MOV A, TOTAL_CEN
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, TOTAL_DEC
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	MOV A, TOTAL_UNI
	ACALL HEX_ASCII
	MOV DBUS, A
	ACALL ESCRIBE_DATO
	
	RET
	
SEND_DATO: ;ENVIA UN SOLO DATO POR SERIAL
    JNB TI, $	;ESPERA HASTA QUE ENVIA EL DATO	
	CPL TI
	MOV SBUF, A
	RET

    
SEND_ALL: ;ENVÍA TODOS LOS DATOS DE LA PANTALLA POR SERIAL (LITROS EN UNI, DEC Y CEN)

	SETB TI		;INICIALIZA BANDERA (ESTA LISTO PARA ENVIAR)
	SETB TR1	;PONE A CONTAR EL TIMER 1	
  
	MOV A, #20H   ;ENVIA EL DATO QUE CONTIENE LA DIRECCIÓN QUE ESTA ENVIANDO
	ACALL SEND_DATO  
      
	MOV A, #20H
	ACALL SEND_DATO 

	MOV A, LITROS_CEN
	ACALL HEX_ASCII
	ACALL SEND_DATO  
  
	MOV A, LITROS_DEC
	ACALL HEX_ASCII
	ACALL SEND_DATO 
  
	MOV A, LITROS_UNI
	ACALL HEX_ASCII
	ACALL SEND_DATO 
  
	MOV A, #20H
	ACALL SEND_DATO 
  
	MOV A, #20H
	ACALL SEND_DATO 
  
	MOV A, #0FFH
	ACALL SEND_DATO
		
	FIN_SEND: 
	SETB TI		;TERMINA DE ENVIAR Y QUEDA EN ESPERA
	CLR TR1		;TIMER 1 DEJA DE CONTAR
	RET	
	
	
	
	
ORG 1000H
	
DB '0'
DB '1'
DB '2'
DB '3'
DB '4'
DB '5'
DB '6'
DB '7'
DB '8'
DB '9'

	
END
