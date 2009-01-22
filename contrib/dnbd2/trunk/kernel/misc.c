/*
 * kernel/misc.c
 */


#include "dnbd2.h"
#include "misc.h"


uint16_t diff(uint16_t then)
{
	int diff = jiffies & 0xffff;
	diff -= then;
        if (diff < 0)
                diff += 1 << 16;
	return diff;
}


int sock_xmit(struct socket *sock, int send, void *buf, int size)
{
	int result;
	struct msghdr msg;
	struct kvec iov;
	unsigned long flags;
	sigset_t oldset;

	spin_lock_irqsave(&current->sighand->siglock, flags);
	oldset = current->blocked;
	sigfillset(&current->blocked);
	sigdelsetmask(&current->blocked, sigmask(SIGKILL));
	recalc_sigpending();
	spin_unlock_irqrestore(&current->sighand->siglock, flags);

	do {
		sock->sk->sk_allocation = GFP_NOIO;
		iov.iov_base = buf;
		iov.iov_len = size;
		msg.msg_name = NULL;
		msg.msg_namelen = 0;
		msg.msg_control = NULL;
		msg.msg_controllen = 0;
		msg.msg_flags = MSG_NOSIGNAL;

		if (send)
			result = kernel_sendmsg(sock, &msg, &iov, 1, size);
		else
			result = kernel_recvmsg(sock, &msg, &iov, 1, size, 0);

		if (signal_pending(current)) {
			siginfo_t info;
			spin_lock_irqsave(&current->sighand->siglock, flags);
			dequeue_signal(current, &current->blocked, &info);
			spin_unlock_irqrestore(&current->sighand->siglock,
					       flags);
			result = -EINTR;
			break;
		}

		if (result <= 0) {
			if (result == 0)
				result = -EPIPE;
			break;
		}
		size -= result;
		buf += result;
	} while (size > 0);

	spin_lock_irqsave(&current->sighand->siglock, flags);
	current->blocked = oldset;
	recalc_sigpending();
	spin_unlock_irqrestore(&current->sighand->siglock, flags);

	return result;
}


char *inet_ntoa(uint32_t ip)
{
	static char buf[sizeof "aaa.bbb.ccc.ddd"];
	unsigned char *nums = (unsigned char *)&ip;
	sprintf(buf, "%u.%u.%u.%u", nums[0], nums[1], nums[2], nums[3]);
	return buf;
}
