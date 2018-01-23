#include <errno.h>

#include "nl80211.h"
#include "iw.h"
#include <unistd.h>

SECTION(measurement);

 /**
  * struct ftm_target - data for an FTM target (FTM responder)
  *
  * @freq: target's frequency
  * @bw: target's bandwith. one of @enum nl80211_chan_width
  * @center_freq1: target's center frequency, 1st segment
  * @center_freq2: target's center frequency, 2nd segment(if relevant)
  * @target: target's mac address.
  * @samples_per_burst: number of FTM frames in a single burst.
  * @one_sided: whether to perform a one-sided or two-sided measurement.
  * @asap: Whether to perform the measurement in ASAP mode. Ignored if
  *	one-sided.
  */
struct ftm_target {
	int freq;
	char bw;
	int center_freq1;
	int center_freq2;
	char target[ETH_ALEN];
	char samples_per_burst;
	char one_sided;
	char asap;
	char num_of_bursts_exp;
	unsigned short burst_period;
	char retries;
	char burst_duration;
	char query_lci;
	char query_civic;
};

static int ftm_put_target(struct nl_msg *msg, struct ftm_target *tgt)
{
	if (nla_put(msg, NL80211_FTM_TARGET_ATTR_BSSID, ETH_ALEN,
		     tgt->target) ||
	    nla_put_u8(msg, NL80211_FTM_TARGET_ATTR_BW, tgt->bw) ||
	    nla_put_u32(msg, NL80211_FTM_TARGET_ATTR_FREQ, tgt->freq) ||
	    (tgt->center_freq1 &&
	     nla_put_u32(msg, NL80211_FTM_TARGET_ATTR_CNTR_FREQ_1,
			 tgt->center_freq1)) ||
	    (tgt->center_freq2 &&
	     nla_put_u32(msg, NL80211_FTM_TARGET_ATTR_CNTR_FREQ_2,
			 tgt->center_freq2)) ||
	    (tgt->samples_per_burst &&
	     nla_put_u8(msg, NL80211_FTM_TARGET_ATTR_SAMPLES_PER_BURST,
			tgt->samples_per_burst)) ||
	    (tgt->num_of_bursts_exp &&
	     nla_put_u8(msg, NL80211_FTM_TARGET_ATTR_NUM_OF_BURSTS_EXP,
			tgt->num_of_bursts_exp)) ||
	    (tgt->burst_period &&
	     nla_put_u16(msg, NL80211_FTM_TARGET_ATTR_BURST_PERIOD,
			 tgt->burst_period)) ||
	     (tgt->retries &&
	      nla_put_u8(msg, NL80211_FTM_TARGET_ATTR_RETRIES,
			 tgt->retries)) ||
	     (tgt->burst_duration &&
	      nla_put_u8(msg, NL80211_FTM_TARGET_ATTR_BURST_DURATION,
			 tgt->burst_duration)) ||
	     (tgt->query_lci &&
	      nla_put_flag(msg, NL80211_FTM_TARGET_ATTR_QUERY_LCI)) ||
	     (tgt->query_civic &&
	      nla_put_flag(msg, NL80211_FTM_TARGET_ATTR_QUERY_CIVIC)))
		return -ENOBUFS;

	if (tgt->one_sided) {
		if (nla_put_flag(msg, NL80211_FTM_TARGET_ATTR_ONE_SIDED))
			return -ENOBUFS;
	} else if (tgt->asap) {
		if (nla_put_flag(msg, NL80211_FTM_TARGET_ATTR_ASAP))
			return -ENOBUFS;
	}

	return 0;
}

static int parse_ftm_target(char *str, struct ftm_target *target)
{
	int res, consumed;
	char bw[6] = {0}, *pos, *tmp, *save_ptr, *delims = " \t\n";

	res = sscanf(str, "%hhx:%hhx:%hhx:%hhx:%hhx:%hhx bw=%5s cf=%d%n",
		     &target->target[0], &target->target[1], &target->target[2],
		     &target->target[3], &target->target[4], &target->target[5],
		     bw, &target->freq, &consumed);

	if (res != 8)
		return -1;

	target->bw = str_to_bw(bw);

	str += consumed;
	pos = strtok_r(str, delims, &save_ptr);

	while (pos) {
		if (strncmp(pos, "cf1=", 4) == 0) {
			target->center_freq1 = strtol(pos + 4, &tmp, 10);
			if (*tmp) {
				printf("Invalid cf1 value!\n");
				return -1;
			}
		} else if (strncmp(pos, "cf2=", 4) == 0) {
			target->center_freq2 = strtol(pos + 4, &tmp, 10);
			if (*tmp) {
				printf("Invalid cf2 value!\n");
				return -1;
			}
		} else if (strncmp(pos, "bursts_exp=", 11) == 0) {
			target->num_of_bursts_exp = strtol(pos + 11, &tmp, 10);
			if (*tmp) {
				printf("Invalid bursts_exp value!\n");
				return -1;
			}
		} else if (strncmp(pos, "burst_period=", 13) == 0) {
			target->burst_period= strtol(pos + 13, &tmp, 10);
			if (*tmp) {
				printf("Invalid burst_period value!\n");
				return -1;
			}
		} else if (strncmp(pos, "retries=", 8) == 0) {
			target->retries = strtol(pos + 8, &tmp, 10);
			if (*tmp) {
				printf("Invalid retries value!\n");
				return -1;
			}
		} else if (strncmp(pos, "burst_duration=", 15) == 0) {
			target->burst_duration = strtol(pos + 15, &tmp, 10);
			if (*tmp) {
				printf("Invalid burst_duration value!\n");
				return -1;
			}
		} else if (strncmp(pos, "spb=", 4) == 0) {
			target->samples_per_burst = strtol(pos + 4, &tmp, 10);
			if (tmp - pos <= 4) {
				printf("Invalid spb value!\n");
				return -1;
			}
		} else if (strcmp(pos, "one-sided") == 0) {
			target->one_sided = 1;
		} else if (strcmp(pos, "asap") == 0) {
			target->asap = 1;
		} else if (strcmp(pos, "civic") == 0) {
			target->query_civic = 1;
		} else if (strcmp(pos, "lci") == 0) {
			target->query_lci = 1;
		} else {
			printf("Unknown parameter %s\n", pos);
			return -1;
		}

		pos = strtok_r(NULL, delims, &save_ptr);
	}

	return 0;
}

static int parse_ftm_mac_rand(char *str, __u8 *template, __u8 *mask)
{
	int res;
	char macbuf[6 * 3];
	char macmask[6 * 3];

	res = sscanf(str, "template=%s mask=%s", macbuf, macmask);
	if (res != 2)
		return 0;

	if (mac_addr_a2n(template, macbuf))
		return -1;

	if (mac_addr_a2n(mask, macmask))
		return -1;

	/* Don't randomize the MC bit */
	if (!(mask[0] & 0x01)) {
		printf("The MC bit must not be randomized");
		return -1;
	}

	return 1;
}

static int parse_ftm_config(const char *conf_file, struct ftm_target **ptargets,
			    __u8 *template, __u8 *mask)
{
	FILE *input;
	char line[256];
	int i, line_num;
	struct ftm_target *targets = NULL, *tmp;
	int res, mac_set = 0;

	input = fopen(conf_file, "r");
	if (!input) {
		printf("The given path does not exist!\n");
		return -1;
	}

	for (i = 0, line_num = 1; fgets(line, sizeof(line), input); line_num++) {
		struct ftm_target tgt = {0};

		if (strncmp(line, "#", 1) == 0)
			continue;

		res = parse_ftm_mac_rand(line, template, mask);
		if (res < 0 || (res > 0 && mac_set)) {
			printf("Invalid FTM configuration at line %d!\n",
			       line_num);
			free(targets);
			return -1;
		}

		if (res > 0) {
			mac_set = 1;
			continue;
		}

		if (parse_ftm_target(line, &tgt)) {
			printf("Invalid FTM configuration at line %d!\n",
			       line_num);
			free(targets);
			return -1;
		}

		i++;
		tmp = realloc(targets, i * sizeof(struct ftm_target));
		if (!tmp) {
			printf("Failed to allocate targets\n");
			free(targets);
			return -1;
		}
		targets = tmp;
		targets[i - 1] = tgt;
	}

	*ptargets = targets;
	return i;
}

static int handle_ftm_req(struct nl80211_state *state, struct nl_msg *msg,
			  int argc, char **argv, enum id_input id)
{
	int err;
	static char *req_argv[4] = {
		NULL,
		"measurement",
		"ftm_request_send",
		NULL,
	};
	static const __u32 cmds[] = {
		NL80211_CMD_MSRMENT_REQUEST,
		NL80211_CMD_MSRMENT_RESPONSE,
	};
	struct print_event_args printargs = { };

	if (argc != 4)
		return 1;

	req_argv[0] = argv[0];
	req_argv[3] = argv[3];

	err = handle_cmd(state, id, 4, req_argv);
	if (err)
		return err;

	__do_listen_events(state, ARRAY_SIZE(cmds), cmds, &printargs);
	return 0;
}

static int handle_ftm_req_send(struct nl80211_state *state, struct nl_msg *msg,
			       int argc, char **argv, enum id_input id)
{
	struct nlattr *nl_ftm_req, *nl_targets, *nl_target;
	__u8 macaddr[ETH_ALEN] = {0};
	/* Dont randomize the MC bit */
	__u8 macaddr_mask[ETH_ALEN] = {0x01, };
	struct ftm_target *targets;
	int i, num_targets = 0;

	if (argc != 1)
		return 1;

	num_targets = parse_ftm_config(argv[0], &targets, macaddr, macaddr_mask);
	if (num_targets <= 0)
		return 1;

	NLA_PUT_U32(msg, NL80211_ATTR_MSRMENT_TYPE, NL80211_MSRMENT_TYPE_FTM);

	nl_ftm_req = nla_nest_start(msg, NL80211_ATTR_MSRMENT_FTM_REQUEST);
	if (!nl_ftm_req)
		goto nla_put_failure;

	NLA_PUT(msg, NL80211_FTM_REQ_ATTR_MACADDR_TEMPLATE, ETH_ALEN, macaddr);
	NLA_PUT(msg, NL80211_FTM_REQ_ATTR_MACADDR_MASK, ETH_ALEN, macaddr_mask);

	nl_targets = nla_nest_start(msg, NL80211_FTM_REQ_ATTR_TARGETS);
	if (!nl_targets)
		goto nla_put_failure;

	for (i = 0; i < num_targets; i++) {
		nl_target = nla_nest_start(msg, i);
		if (!nl_target || ftm_put_target(msg, &targets[i]))
			goto nla_put_failure;
		nla_nest_end(msg, nl_target);
	}

	nla_nest_end(msg, nl_targets);
	nla_nest_end(msg, nl_ftm_req);

	free(targets);
	return 0;

nla_put_failure:
	free(targets);
	return -ENOBUFS;
}
COMMAND(measurement, ftm_request, "<config-file>", 0, 0,
	CIB_NETDEV, handle_ftm_req,
	"Send an FTM request to the targets supplied in the config file.\n"
	"Each line in the file represents a target, with the following format:\n"
	"<bssid> bw=<[20|40|80|80+80|160]> cf=<center_freq> [cf1=<center_freq1>] [cf2=<center_freq2>] [spb=<samples per burst>] [one-sided] [asap] [bursts_exp=<num of bursts exponent>] [burst_period=<burst period>] [retries=<num of retries>] [burst_duration=<burst duration>] [civic] [lci]\n"
	"To set the MAC address randomization template and mask, add the line:\n"
	"template=<mac address template> mask=<mac address mask>");
HIDDEN(measurement, ftm_request_send, "<config-file>", NL80211_CMD_MSRMENT_REQUEST, 0,
	CIB_NETDEV, handle_ftm_req_send);
