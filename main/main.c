#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#define MAX_BUFFER 1024
#define SYSFS_FILE_NAME_IN "/sys/kernel/sykt_sysfs/dskrwo"
#define SYSFS_FILE_NAME_CTRL "/sys/kernel/sykt_sysfs/dtkrwo"
#define SYSFS_FILE_NAME_STATE "/sys/kernel/sykt_sysfs/dckrwo"
#define SYSFS_FILE_NAME_RESULT "/sys/kernel/sykt_sysfs/drkrwo"

#define PUT 0x01
#define GET 0x02
#define CLR 0x03

#define STATE_BUSY 0x00
#define STATE_READ 0x01
#define STATE_FULL 0x02
#define STATE_READY 0x03

int stan;
int wynik_int;

int sprawdz_stan(){
    int out_file = open(SYSFS_FILE_NAME_STATE, O_RDWR);
    sread(out_file, stan);
    close(out_file);
    return stan;
}

void polecenie(char ctrl)
{
    if (ctrl > 3)
    {
        printf("Niepoprawne polecenie");
        return;
    }
    int ctrl_file = open(SYSFS_FILE_NAME_CTRL, O_RDWR);
    int n = write(ctrl_file, ctrl, 1); // właściwe przekazanie danych
    if (n != 1)
    {
        printf("Nie udalo sie wpisac polecenia");
        int n = write("", ctrl, 0); // błąd wpisywania danych
    }
    close(ctrl_file);
}

void wpisz_dane_do_checksumy(char *buf, size_t length)
{
    
    if(length>250){
        printf("Za dlugi ciag danych wejsciowych");
        return;
    }
    polecenie(CLR);
    int in_file = open(SYSFS_FILE_NAME_IN, O_RDWR);
    for (int i = 0; i < length; i++)
    {
        int n = write(in_file, buf[i], 1); // właściwe przekazanie danych
        if (n != 1)
        {
            printf("Nie udalo sie wpisac danych wejsciowych");
            int n = write("", ctrl, 0); // błąd wpisywania
        }
        polecenie(PUT);
    }
}

void czekaj_na_wynik()
{
    while(sprawdz_stan() == STATE_BUSY){
        continue;
    }
    return;
}

void wypisz_wynik()
{
    int out_file = open(SYSFS_FILE_NAME_RESULT, O_RDWR);
    sread(out_file, wynik_int);
    close(out_file);
    printf("%04X", wynik_int);
    return wynik_int;
}

int main(void)
{
    printf("Compiled at %s %s\n", __DATE__, __TIME__);
    wpisz_dane_do_checksumy(0xBA101A10);
    polecenie(GET);
    czekaj_na_wynik();
    wypisz_wynik();
    return 0;
}