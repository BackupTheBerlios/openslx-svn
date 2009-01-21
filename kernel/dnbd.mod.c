#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

#undef unix
struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = __stringify(KBUILD_MODNAME),
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
};

static const struct modversion_info ____versions[]
__attribute_used__
__attribute__((section("__versions"))) = {
	{ 0xaeca800e, "struct_module" },
	{ 0x738c2317, "blk_init_queue" },
	{ 0x4f2dbd50, "module_refcount" },
	{ 0x77414029, "__kmalloc" },
	{ 0x736e81f3, "__mod_timer" },
	{ 0xa05d1ea5, "alloc_disk" },
	{ 0x114446f3, "blk_cleanup_queue" },
	{ 0x1371d8b7, "kernel_sendmsg" },
	{ 0x37233b03, "mem_map" },
	{ 0x5b531014, "del_timer" },
	{ 0x79aa04a2, "get_random_bytes" },
	{ 0x3de88ff0, "malloc_sizes" },
	{ 0xc262aafa, "remove_wait_queue" },
	{ 0xe241f67a, "end_that_request_last" },
	{ 0x1751f3de, "sub_preempt_count" },
	{ 0xb85ed16f, "remove_proc_entry" },
	{ 0xaf7d078b, "skb_recv_datagram" },
	{ 0x1d26aa98, "sprintf" },
	{ 0x7d11c268, "jiffies" },
	{ 0xc39b00d7, "elv_remove_request" },
	{ 0xffd5a395, "default_wake_function" },
	{ 0xdc016488, "wait_for_completion" },
	{ 0xf209f11e, "vfs_read" },
	{ 0x64a6ed7f, "skb_checksum" },
	{ 0x3328c1ed, "proc_mkdir" },
	{ 0x1b7d4074, "printk" },
	{ 0x96964ed8, "del_gendisk" },
	{ 0xc917e655, "debug_smp_processor_id" },
	{ 0x7ee8c5cb, "rb_erase" },
	{ 0xe5e806f9, "add_preempt_count" },
	{ 0x71a50dbc, "register_blkdev" },
	{ 0x707f93dd, "preempt_schedule" },
	{ 0x3996d817, "fput" },
	{ 0xd79b5a02, "allow_signal" },
	{ 0xeac1c4af, "unregister_blkdev" },
	{ 0x2642591c, "kmem_cache_alloc" },
	{ 0x90487e54, "end_that_request_first" },
	{ 0xa7491ab1, "elv_next_request" },
	{ 0x4292364c, "schedule" },
	{ 0x17d59d01, "schedule_timeout" },
	{ 0xfb6af58d, "recalc_sigpending" },
	{ 0xb43deb6, "put_disk" },
	{ 0x578f9e69, "force_sig" },
	{ 0xdbd72563, "create_proc_entry" },
	{ 0xdf6c55f, "wake_up_process" },
	{ 0x47c1148d, "skb_copy_datagram_iovec" },
	{ 0x7ec51f67, "rb_insert_color" },
	{ 0xb88d5b57, "kernel_recvmsg" },
	{ 0x56cf98bd, "init_timer" },
	{ 0xbce89f77, "__wake_up" },
	{ 0xadbc2c9a, "add_wait_queue" },
	{ 0x37a0cba, "kfree" },
	{ 0x5bc6b34, "add_disk" },
	{ 0xd927620f, "fget" },
	{ 0x7e9ebb05, "kernel_thread" },
	{ 0x60a4461c, "__up_wakeup" },
	{ 0x942613ad, "complete" },
	{ 0x25da070, "snprintf" },
	{ 0xf6ae1c9c, "set_blocksize" },
	{ 0x96b27088, "__down_failed" },
	{ 0xd6c963c, "copy_from_user" },
	{ 0xdc43a9c8, "daemonize" },
	{ 0xad39c6bf, "vfs_write" },
	{ 0x7c795f4, "generic_fillattr" },
	{ 0xf562199b, "skb_free_datagram" },
	{ 0x8a22826, "filp_open" },
};

static const char __module_depends[]
__attribute_used__
__attribute__((section(".modinfo"))) =
"depends=";

