#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/ioport.h>
#include <asm/errno.h>
#include <asm/io.h>
MODULE_INFO(intree, "Y");
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Wojciech Królak-Kurkus");
MODULE_DESCRIPTION("Simple kernel module for SYKOM lecture");
MODULE_VERSION("0.01");

#define RAW_SPACE(addr) (*(volatile unsigned long *)(addr))

#define SYKT_GPIO_BASE_ADDR (0x00100000)

#define IN_ADDR (0x00000640)
#define CTRL_ADDR (0x00000658)

#define STATE_ADDR (0x00000648)
#define RESULT_ADDR (0x00000650)

#define SYKT_GPIO_SIZE (0x8000)
#define SYKT_EXIT (0x3333)
#define SYKT_EXIT_CODE (0x7F)

void __iomem *baseptr;

static struct kobject *kobj_ref;
static int dskrwo; // IN
static int dtkrwo; // CTRL
static int dckrwo; // STATE
static int drkrwo; // RESULT

static ssize_t dskrwo_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    size_t i;
    char wynik = 0;

    if (count == 0 || count > 4)
    {
        return -EINVAL;
    }

    // walidacja zapisu ósemkowego i ilości bitów
    for (i = 0; i < count; i++)
    {
        char c = buf[i];
        char liczba;

        // odrzucanie ewentualnego newlinea z końca pliku
        if (i == count - 1 && c == '\n')
            continue;

        if (c < '0' || c > '7')
        {
            return -EINVAL;
        }
        liczba = c - '0';

        if (wynik > 0377 >> 3)
        { // Sprawdza, czy po przesunięciu byłby overflow
            return -EINVAL;
        }

        wynik = (wynik << 3) | liczba; // pipe (operacja OR) daje taki sam rezultat co +, ale podobno jest wydajniejszy
    }

    dskrwo = wynik;
    writel(dskrwo, baseptr + IN_ADDR);
    return count;
}
static ssize_t dtkrwo_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    if (count == 0 || count > 2 || (count == 2 && buf[1] != '\n'))
    {
        return -EINVAL;
    }
    if (buf[0] < '0' || buf[0] > '3')
    {
        return -EINVAL;
    }
    dtkrwo = buf[0] - '0';
    
    writel(dtkrwo, baseptr + CTRL_ADDR);
    return count;
}
static ssize_t dckrwo_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    dckrwo = readl(baseptr+STATE_ADDR);
    return sprintf(buf, "%x", dckrwo);
}
static ssize_t drkrwo_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    drkrwo = readl(baseptr+RESULT_ADDR);
    return sprintf(buf, "%x", drkrwo);
}

// tylko do zapisu
static struct kobj_attribute dskrwo_attr = __ATTR_WO(dskrwo); // IN
static struct kobj_attribute dtkrwo_attr = __ATTR_WO(dtkrwo); // CTRL

// tylko do odczytu
static struct kobj_attribute dckrwo_attr = __ATTR_RO(dckrwo); // STATE
static struct kobj_attribute drkrwo_attr = __ATTR_RO(drkrwo); // RESULT

int my_init_module(void)
{
    printk(KERN_INFO "Init my module.\n");
    baseptr = ioremap(SYKT_GPIO_BASE_ADDR, SYKT_GPIO_SIZE);

    kobj_ref = kobject_create_and_add("sykt", kernel_kobj);

    if (!kobj_ref)
    {
        printk(KERN_INFO "Failed to create kobject.\n");
    }
    if (sysfs_create_file(kobj_ref, &dskrwo_attr.attr))
    {
        printk(KERN_INFO "Failed to create sysfs file.\n");
    }
    if (sysfs_create_file(kobj_ref, &dtkrwo_attr.attr))
    {
        printk(KERN_INFO "Failed to create sysfs file.n");
        sysfs_remove_file(kernel_kobj, &dskrwo_attr.attr);
    }
    if (sysfs_create_file(kobj_ref, &dckrwo_attr.attr))
    {
        printk(KERN_INFO "Failed to create sysfs file.n");
        sysfs_remove_file(kernel_kobj, &dskrwo_attr.attr);
        sysfs_remove_file(kernel_kobj, &dtkrwo_attr.attr);
    }
    if (sysfs_create_file(kobj_ref, &drkrwo_attr.attr))
    {
        printk(KERN_INFO "Failed to create sysfs file.n");
        sysfs_remove_file(kernel_kobj, &dskrwo_attr.attr);
        sysfs_remove_file(kernel_kobj, &dtkrwo_attr.attr);
        sysfs_remove_file(kernel_kobj, &dckrwo_attr.attr);
    }
    return 0;
}
void my_cleanup_module(void)
{
    printk(KERN_INFO "Cleanup my module.\n");
    writel(SYKT_EXIT | ((SYKT_EXIT_CODE) << 16), baseptr);
    sysfs_remove_file(kernel_kobj, &dskrwo_attr.attr);
    sysfs_remove_file(kernel_kobj, &dtkrwo_attr.attr);
    sysfs_remove_file(kernel_kobj, &dckrwo_attr.attr);
    sysfs_remove_file(kernel_kobj, &drkrwo_attr.attr);
    iounmap(baseptr);
}
module_init(my_init_module)
module_exit(my_cleanup_module)