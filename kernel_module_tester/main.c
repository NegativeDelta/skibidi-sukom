#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <stdint.h>

#define SYSFS_FILE_NAME_IN "/sys/kernel/sykom/dskrwo"
#define SYSFS_FILE_NAME_CTRL "/sys/kernel/sykom/dtkrwo"
#define SYSFS_FILE_NAME_STATE "/sys/kernel/sykom/dckrwo"
#define SYSFS_FILE_NAME_RESULT "/sys/kernel/sykom/drkrwo"

#define PUT 0x01
#define GET 0x02
#define CLR 0x03

#define STATE_BUSY 0x00
#define STATE_READ 0x01
#define STATE_FULL 0x02
#define STATE_READY 0x03
#define STATE_ERROR 0x04

int stan;
unsigned int wynik_int;

unsigned int wynikk;

int sprawdz_stan()
{
    int fd = open(SYSFS_FILE_NAME_STATE, O_RDONLY);
    if (fd < 0)
    {
        printf("Blad otwierania dckrwo\n");
        return -1;
    }

    char buf[16];
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);

    if (n <= 0)
        return -1;

    buf[n] = '\0';
    return (int)strtol(buf, NULL, 16);
}

int polecenie(char ctrl, int fd_ctrl)
{
    usleep(10000); 
    char cmd[2] = {'0' + ctrl, '\0'};
    write(fd_ctrl, cmd, 1);
    fsync(fd_ctrl);
    usleep(10000); 
    return 0;
}

int wpisz_bajt(char bajt, int fd_in, int fd_ctrl)
{
    char byte_str[4];
    snprintf(byte_str, sizeof(byte_str), "%o", bajt);


    write(fd_in, byte_str, strlen(byte_str));
    fsync(fd_in);

    if (polecenie(PUT, fd_ctrl) < 0)
    {
        printf("Blad wydawania polecenia\n");
        return -1;
    }

    return 0;
}

int wpisz_dane_do_checksumy(char *buf, size_t length, int fd_in, int fd_ctrl)
{
    if (length > 250)
    {
        printf("Za dlugi ciag danych wejsciowych!\n");
        return -1;
    }

    if (polecenie(CLR, fd_ctrl) < 0)
    {
        printf("Blad wydawania polecenia\n");
        return -1;
    }

    for (size_t i = 0; i < length; i++)
    {

        if (wpisz_bajt(buf[i], fd_in, fd_ctrl) < 0)
        {
            return -1;
        }
    }

    return 0;
}

int wpisz_dane_do_checksumy_unsafe(char *buf, size_t length, int fd_in, int fd_ctrl)
{


    if (polecenie(CLR, fd_ctrl) < 0)
    {
        printf("Blad wydawania polecenia\n");
        return -1;
    }

    for (size_t i = 0; i < length; i++)
    {

        if (wpisz_bajt(buf[i], fd_in, fd_ctrl) < 0)
        {
            return -1;
        }
    }

    return 0;
}

void czekaj_na_wynik()
{
    while (sprawdz_stan() == STATE_BUSY)
    {
        usleep(200);
        continue;
    }
    return;
}

unsigned int wez_wynik()
{
    int out_file = open(SYSFS_FILE_NAME_RESULT, O_RDONLY); 
    char buf[13];
    ssize_t n = read(out_file, buf, sizeof(buf));
    if (n > 0)
    {
        wynik_int = strtoul(buf, NULL, 8); 
    }
    close(out_file);
    return wynik_int;
}

unsigned int oblicz_crc(char *data, int fd_ctrl, int fd_in)
{
    if(wpisz_dane_do_checksumy(data, strlen(data), fd_in, fd_ctrl) < 0){
        printf("Blad obliczania sumy\n");
        return 0;
    }
    if(polecenie(GET, fd_ctrl) < 0){
        printf("Blad obliczania sumy\n");
        return 0;
    }
    czekaj_na_wynik();
    return wez_wynik();
}


char* czytaj_wejscie() {
    char buffer[250];
    printf("Wpisz tekst, ktorego CRC32ISCSI chcesz obliczyc (aby wyjsc, wcisnij enter bez wpisywania niczego): ");
    
    if (fgets(buffer, 250, stdin) == NULL) {
        return NULL; 
    }
    

    size_t len = strlen(buffer);
    if (len > 0 && buffer[len-1] == '\n') {
        buffer[len-1] = '\0';
    }

    return strdup(buffer);
}

uint64_t get_time_ms() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000 + (uint64_t)ts.tv_nsec / 1000000;
}

int main(void)
{
    int fd_ctrl = open(SYSFS_FILE_NAME_CTRL, O_WRONLY);
    int fd_in = open(SYSFS_FILE_NAME_IN, O_WRONLY);

    if (fd_ctrl < 0 || fd_in < 0)
    {
        printf("Blad otwierania plikow sysfs\n");
        return -1;
    }

    printf("Compiled at %s %s\n", __DATE__, __TIME__);

    char wektory_testowe[5][251] = {"", "test", "sykom", "wojciech", "sykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykomsykom"};
    unsigned int expected[5] = {0x00000000, 0x86a072c0, 0x5d293ed5, 0xb0cbca92, 0xc8eca170};
    
    uint64_t start, end;

    for (int i = 0; i < 5; i += 1)
    {
        start = get_time_ms();
        wynikk = oblicz_crc(wektory_testowe[i], fd_ctrl, fd_in);
        end = get_time_ms();
        if (wynikk == expected[i])
        {
            printf("Obliczono poprawnie sume '%s': %08X\n", wektory_testowe[i], wynikk);
            printf("Czas obliczania sumy: %.llu ms.\n\n", (unsigned long long)(end-start));
        }
        else
        {
            printf("BLAD: Suma'%s' wyszla %04X zamiast %08X\n\n", wektory_testowe[i], wynikk, expected[i]);
        }
    }
    
    char lipsum[252] = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut id egestas neque, et egestas mi. Nam ultrices pellentesque turpis pulvinar rhoncus. Sed euismod quam vel sapien molestie, eget vestibulum leo luctus. In pulvinar sapien velit, nec tincidunt m";
    wpisz_dane_do_checksumy_unsafe(lipsum, 251, fd_in, fd_ctrl);
    printf("Stan modulu po wpisaniu 251 bajtow: %08X\n", sprawdz_stan());
    
    close(fd_in);
    close(fd_ctrl);

    while (1)
    {
        char *user_input = czytaj_wejscie();

        // pusty input
        if (strlen(user_input) == 0)
        {
            free(user_input);
            break; 
        }
        fd_ctrl = open(SYSFS_FILE_NAME_CTRL, O_WRONLY);
        fd_in = open(SYSFS_FILE_NAME_IN, O_WRONLY);
        if (fd_ctrl < 0 || fd_in < 0)
        {
            perror("Blad otwierania plikow sysfs");
            return -1;
        }
        wynikk = oblicz_crc(user_input, fd_ctrl, fd_in);
        close(fd_in);
        close(fd_ctrl);
        printf("CRC32ISCSI ciagu znakow '%s' to: %08X\n", user_input, wynikk);

        free(user_input);
    }

    return 0;
}