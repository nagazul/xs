## Versioning
```
# bump script patch version (add whatever files you want into the bump commit)
git add xlog/README.md xlog/CHANGELOG.md
make bump xlog
```
For major/minor bumps, use `make bump <script> major` or `make bump <script> minor`.  
