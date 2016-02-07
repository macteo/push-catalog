# Push-Catalog

To send a push notification:

- Open terminal
- Install houston gem (first time only)

```
[sudo] gem install houston
```

- Got to the Send folder

```
cd Send
```

- To send a generic push to development devices:

```bash
./push.sh
```

- To send a generic push to production devices:

```bash
./push.sh * p
```

- To send a push with a category to development devices:

```bash
./push.sh c p
```

- You can define custom payload messages inside the push.sh file and invoke them with the first parameter.
