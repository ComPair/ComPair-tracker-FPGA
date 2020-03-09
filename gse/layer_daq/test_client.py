import silayer

tx = silayer.client.Client(host='10.10.0.11')

tx.set_config(0, "/home/root//vatactrl/default.config")

tx.get_n_fifo(0)

tx.exit()